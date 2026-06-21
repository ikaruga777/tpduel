# Smoke test for the core game logic and the realtime RoomChannel.
# Run with:  bin/rails runner script/smoke_test.rb
#
# It exercises the model lifecycle (create → start → progress → win → rematch)
# and the channel flow (identity, host-only start, progress, finish broadcasts)
# without needing a browser. Safe to run against the development database — it
# only touches the rows it creates.

require "action_cable/channel/test_case"

failures = 0
check = ->(label, cond) do
  puts "#{cond ? "✅" : "❌"} #{label}"
  failures += 1 unless cond
end

# Capture channel broadcasts by overriding the class method for the test run.
captured = []
RoomChannel.define_singleton_method(:broadcast_to) { |_target, message| captured << message }
capture = ->(blk) { captured.clear; blk.call; captured.last }

# ---- Model lifecycle --------------------------------------------------------
room  = Room.create!
host  = room.players.create!(nickname: "Alice", token: "smoke-#{SecureRandom.hex(4)}", host: true)
guest = room.players.create!(nickname: "Bob",   token: "smoke-#{SecureRandom.hex(4)}")

check.("room code is 6 chars", room.code.length == 6)
check.("room starts in waiting", room.waiting?)
check.("ready to start with 2 players", room.ready_to_start?)
check.("host lookup works", room.host == host)

room.start!
room.reload
check.("playing after start!", room.playing?)
check.("prompt assigned", room.prompt_text.present?)
check.("countdown scheduled (started_at in future)", room.started_at > Time.current)
check.("progress reset for all players", room.players.all? { |p| p.progress.zero? })

guest.update!(progress: 12)
check.("declare_winner returns first finisher", room.declare_winner(guest) == guest)
check.("finished after a winner", room.reload.finished?)
check.("declare_winner is idempotent", room.declare_winner(host) == guest)
check.("loser not marked finished", host.reload.finished_at.nil?)

room.rematch!
check.("rematch! returns to playing", room.reload.playing?)
check.("rematch! clears previous winner", room.winner_id.nil?)

# ---- Channel flow -----------------------------------------------------------
params = { "code" => room.code }.with_indifferent_access
rejected = ->(chan) { chan.send(:subscription_rejected?) }

guest_conn = ActionCable::Channel::ConnectionStub.new(player_token: guest.token)
guest_chan = RoomChannel.new(guest_conn, "g", params)
guest_chan.subscribe_to_channel
check.("valid player subscription accepted", !rejected.(guest_chan))

stranger = RoomChannel.new(
  ActionCable::Channel::ConnectionStub.new(player_token: "unknown"), "x", params
)
stranger.subscribe_to_channel
check.("unknown player rejected", rejected.(stranger))

check.("non-host start is ignored", capture.(-> { guest_chan.start }).nil?)

host_chan = RoomChannel.new(
  ActionCable::Channel::ConnectionStub.new(player_token: host.token), "h", params
)
host_chan.subscribe_to_channel
start_msg = capture.(-> { host_chan.start })
check.("host start broadcasts type=start", start_msg && start_msg[:type] == "start")
check.("start broadcast carries a prompt", start_msg && start_msg[:prompt].present?)

prog_msg = capture.(-> { guest_chan.progress({ "progress" => 7 }) })
check.("progress broadcasts type=progress", prog_msg && prog_msg[:type] == "progress")
check.("progress value persisted", guest.reload.progress == 7)

finish_msg = capture.(-> { guest_chan.finish })
check.("finish broadcasts type=finished", finish_msg && finish_msg[:type] == "finished")
check.("finish records the winner", room.reload.winner == guest)

# ---- Cleanup ----------------------------------------------------------------
room.destroy

puts ""
if failures.zero?
  puts "ALL PASSED ✨"
else
  puts "#{failures} CHECK(S) FAILED"
  exit 1
end

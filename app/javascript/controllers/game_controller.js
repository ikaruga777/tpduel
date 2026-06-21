import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Drives a single room: subscribes to RoomChannel, renders live progress for
// both players, runs the countdown, handles typing and the win/rematch flow.
export default class extends Controller {
  static targets = [
    "players", "status", "countdown", "prompt", "input",
    "result", "startBtn", "hostHint"
  ]
  static values = {
    code: String,
    playerId: Number,
    host: Boolean,
    countdownSeconds: Number
  }

  connect() {
    this.prompt = ""
    this.startTime = null
    this.finishedLocally = false

    this.subscription = consumer.subscriptions.create(
      { channel: "RoomChannel", code: this.codeValue },
      {
        connected: () => {},
        received: (data) => this.received(data)
      }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }

  // ---- Incoming messages ----------------------------------------------------

  received(data) {
    switch (data.type) {
      case "lobby":
        this.renderPlayers(data.players)
        this.updateLobby(data)
        break
      case "start":
        this.renderPlayers(data.players)
        this.beginRound(data)
        break
      case "progress":
        this.updateProgress(data.player_id, data.progress)
        break
      case "finished":
        this.renderPlayers(data.players)
        this.showResult(data)
        break
    }
  }

  // ---- Lobby ----------------------------------------------------------------

  updateLobby(data) {
    if (data.status === "playing") return

    if (data.ready_to_start) {
      this.setStatus("準備完了！")
      if (this.hasStartBtnTarget) {
        this.startBtnTarget.disabled = false
        this.startBtnTarget.textContent = "スタート"
      }
    } else {
      this.setStatus("対戦相手を待っています…")
      if (this.hasStartBtnTarget) this.startBtnTarget.disabled = true
    }
  }

  // Host pressed the start / rematch button.
  start() {
    this.subscription?.perform("start")
  }

  // ---- Round ----------------------------------------------------------------

  beginRound(data) {
    this.prompt = data.prompt || ""
    this.finishedLocally = false
    this.startTime = null

    this.hide(this.resultTarget)
    this.renderPrompt()
    this.inputTarget.value = ""
    this.inputTarget.disabled = true
    this.hide(this.inputTarget)
    if (this.hasStartBtnTarget) this.startBtnTarget.disabled = true
    if (this.hasHostHintTarget) this.hide(this.hostHintTarget)

    const startAtMs = (data.started_at || 0) * 1000
    this.runCountdown(startAtMs)
  }

  runCountdown(startAtMs) {
    this.show(this.countdownTarget)
    const tick = () => {
      const remaining = Math.ceil((startAtMs - Date.now()) / 1000)
      if (remaining > 0) {
        this.countdownTarget.textContent = remaining
        this.setStatus("まもなく開始…")
        setTimeout(tick, 100)
      } else {
        this.countdownTarget.textContent = "GO!"
        setTimeout(() => this.hide(this.countdownTarget), 500)
        this.go()
      }
    }
    tick()
  }

  go() {
    this.setStatus("タイプ！")
    this.show(this.promptTarget)
    this.show(this.inputTarget)
    this.inputTarget.disabled = false
    this.inputTarget.focus()
    this.startTime = performance.now()
  }

  // ---- Typing ---------------------------------------------------------------

  onInput() {
    if (this.finishedLocally || !this.prompt) return

    const value = this.inputTarget.value
    const correct = this.correctPrefixLength(value)
    this.paintPrompt(value, correct)

    const percent = Math.round((correct / this.prompt.length) * 100)
    this.updateProgress(this.playerIdValue, correct)
    this.subscription?.perform("progress", { progress: correct })

    if (value === this.prompt) {
      this.finishedLocally = true
      this.inputTarget.disabled = true
      this.setStatus("打ち切った！結果待ち…")
      this.subscription?.perform("finish")
    }
  }

  blockPaste(event) {
    event.preventDefault()
  }

  correctPrefixLength(value) {
    let i = 0
    while (i < value.length && i < this.prompt.length && value[i] === this.prompt[i]) {
      i++
    }
    return i
  }

  // ---- Result ---------------------------------------------------------------

  showResult(data) {
    this.hide(this.inputTarget)
    this.inputTarget.disabled = true

    const winner = data.players.find((p) => p.id === data.winner_id)
    const iWon = data.winner_id === this.playerIdValue
    const name = winner ? winner.nickname : "?"

    this.resultTarget.innerHTML =
      `<div class="result-badge ${iWon ? "win" : "lose"}">` +
      `${iWon ? "🏆 あなたの勝ち！" : `くやしい… ${this.escape(name)} の勝ち`}` +
      `</div>`
    this.show(this.resultTarget)
    this.setStatus("対戦終了")

    if (this.hostValue && this.hasStartBtnTarget) {
      this.startBtnTarget.disabled = false
      this.startBtnTarget.textContent = "もう一度"
    } else if (this.hasHostHintTarget) {
      this.hostHintTarget.textContent = "ホストの再戦を待っています…"
      this.show(this.hostHintTarget)
    }
  }

  // ---- Rendering helpers ----------------------------------------------------

  renderPlayers(players) {
    this.playersTarget.innerHTML = players.map((p) => this.playerCard(p)).join("")
    players.forEach((p) => this.updateProgressBar(p.id, p.progress))
  }

  playerCard(p) {
    const badges =
      (p.host ? `<span class="badge">HOST</span>` : "") +
      (p.id === this.playerIdValue ? `<span class="badge badge-you">YOU</span>` : "")
    return (
      `<div class="player-card" data-player-id="${p.id}">` +
        `<div class="player-top">` +
          `<span class="player-name">${this.escape(p.nickname)} ${badges}</span>` +
          `<span class="player-pct" data-player-pct>0%</span>` +
        `</div>` +
        `<div class="progress-track">` +
          `<div class="progress-bar" data-player-bar style="width: 0%"></div>` +
        `</div>` +
      `</div>`
    )
  }

  updateProgress(playerId, correctChars) {
    this.updateProgressBar(playerId, correctChars)
  }

  updateProgressBar(playerId, correctChars) {
    const card = this.playersTarget.querySelector(`[data-player-id="${playerId}"]`)
    if (!card) return
    const total = this.prompt.length || 1
    const percent = Math.min(100, Math.round((correctChars / total) * 100))
    const bar = card.querySelector("[data-player-bar]")
    const pct = card.querySelector("[data-player-pct]")
    if (bar) bar.style.width = `${percent}%`
    if (pct) pct.textContent = `${percent}%`
  }

  renderPrompt() {
    this.promptTarget.innerHTML = [...this.prompt]
      .map((ch, i) => `<span class="ch" data-i="${i}">${this.escape(ch)}</span>`)
      .join("")
  }

  paintPrompt(value, correctLen) {
    const spans = this.promptTarget.querySelectorAll(".ch")
    spans.forEach((span, i) => {
      span.classList.remove("correct", "incorrect", "current")
      if (i < correctLen) {
        span.classList.add("correct")
      } else if (i < value.length) {
        span.classList.add("incorrect")
      } else if (i === value.length) {
        span.classList.add("current")
      }
    })
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }

  show(el) { el.classList.remove("hidden") }
  hide(el) { el.classList.add("hidden") }

  escape(str) {
    const div = document.createElement("div")
    div.textContent = str ?? ""
    return div.innerHTML
  }
}

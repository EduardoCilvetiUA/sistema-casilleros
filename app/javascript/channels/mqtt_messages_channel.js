import consumer from "./consumer"

consumer.subscriptions.create("MqttMessagesChannel", {
  connected() {
    console.log("Connected to MQTT messages channel")
  },

  received(data) {
    const messagesContainer = document.getElementById('mqtt-messages')
    if (messagesContainer) {
      const messageDiv = document.createElement('div')
      messageDiv.className = 'mqtt-message'
      messageDiv.innerHTML = `
        <small class="text-muted">${new Date().toLocaleTimeString()}</small>
        <strong>${data.topic}:</strong>
        <pre class="mb-0">${JSON.stringify(JSON.parse(data.message), null, 2)}</pre>
      `
      messagesContainer.insertBefore(messageDiv, messagesContainer.firstChild)
    }
  }
})

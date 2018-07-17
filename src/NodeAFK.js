const Listener = require('./Listener');

class NodeAFK {
  constructor() {
    this.listeners = {};
    this.nextListenerId = 1;
  }

  getAllListeners() {
    return this.listeners;
  }

  // Add a listener to check when the user is away
  // Interval - {Number} of Seconds
  // callback - {Function}
  // Returns a {Number} - The id of the listener that was created
  addListener(interval, callback) {
    const listenerId = this.nextListenerId;
    this.nextListenerId += 1;

    const afkListener = new Listener(listenerId, interval, callback);
    afkListener.checkIsAway();

    this.addListenerToList(listenerId, afkListener);

    return listenerId;
  }

  addListenerToList(id, listener) {
    this.listeners[id] = listener;
  }

  // Remove a listener
  // id - {Number} id of the listener
  // Returns a Boolean of the success of the operation
  removeListener(id) {
    if (this.listeners[id]) {
      this.listeners[id].removeListener();
      delete this.listeners[id];
      return true;
    }

    return false;
  }

  removeAllListeners() {
    Object.values(this.listeners).forEach((listener) => {
      listener.removeListener();
    });

    this.listeners = {};
  }
}

module.exports = new NodeAFK();
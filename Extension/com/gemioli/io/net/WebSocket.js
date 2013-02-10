(function() {
  
  if (window.WebSocket) {
    return;
  } else if (window.MozWebSocket) {
    window.WebSocket = MozWebSocket;
    return;
  }
  window.WebSocket = function(url) {
    var self = this;
    self.__init = setTimeout(function() {
      self.close();
    }, 0);
  };

  WebSocket.prototype.send = function(data) {
  };

  WebSocket.prototype.close = function() {
	if (this.onclose != null)
		this.onclose();
  };
  
})();

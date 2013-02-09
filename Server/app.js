var app = require('http').createServer(handler)
  , io = require('socket.io').listen(app)
  , fs = require('fs')

app.listen(80);

function handler (req, res) {
  fs.readFile(__dirname + '/index.html',
  function (err, data) {
    if (err) {
      res.writeHead(500);
      return res.end('Error loading index.html');
    }
    res.writeHead(200);
    res.end(data);
  });
}

io.sockets.on('connection', function (socket) {
  socket.send('Hello');
  socket.on('message', function(msg) {
	console.log("Client say [" + msg + "]");
  });
  socket.emit("ServerEvent", {name : 'Jerry'});
  socket.on('ClientEventEmpty', function () {
    console.log('ClientEventEmpty');
  });
  socket.on('ClientEventData', function (data) {
    console.log('ClientEventData [' + data.myData + ']');
  });
  socket.on('ClientEventCallback', function (fn) {
    console.log('ClientEventCallback');
	fn('Done');
  });
});

var chat = io
  .of('/chat')
  .on('connection', function(socket) {
	socket.on('message', function (msg) {
	  console.log('New message to chat [' + msg + ']');
	});
	socket.send('hi from chat');
  });
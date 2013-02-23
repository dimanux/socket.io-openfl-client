var app = require('http').createServer(handler)
  , io = require('socket.io').listen(app)
  , fs = require('fs')

io.set('flash policy port', -1)

io.set('transports', [
    'websocket'
  , 'flashsocket'
  , 'htmlfile'
  , 'xhr-polling'
  , 'jsonp-polling'
]);
  
app.listen(8080);

function handler (req, res) {
  if (req.url == '/crossdomain.xml')
  {
	  fs.readFile(__dirname + '/crossdomain.xml',
	  function (err, data) {
		if (err) {
		  res.writeHead(500);
		  return res.end('Error loading cd.xml');
		}
		res.writeHead(200, {'Content-Type': 'text/plain'});
		res.end(data);
	  });
	  return;
  }
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
  socket.emit('ServerEvent', {name : 'Jerry'});
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
  socket.on('Ping', function (data) {
	console.log('Ping packet ' + data);
	socket.emit('Pong', data);
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
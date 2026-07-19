const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 5000;
const HOST = '0.0.0.0';

http.createServer((req, res) => {
  const filePath = path.join(__dirname, 'index.html');
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(500);
      res.end('Erro ao carregar página');
      return;
    }
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(data);
  });
}).listen(PORT, HOST, () => {
  console.log(`✅ Servidor rodando em ${HOST}:${PORT}`);
  console.log(`📡 Adicione essa URL no UptimeRobot para ficar 24h on!\n`);
});

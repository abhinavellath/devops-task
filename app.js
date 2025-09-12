const express = require('express');
const path = require('path');
const app = express();

// Serve static file at root
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'logoswayatt.png'));
});

// Add a dedicated health check endpoint for ALB
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Listen on 0.0.0.0 for ECS
app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on http://0.0.0.0:3000');
});

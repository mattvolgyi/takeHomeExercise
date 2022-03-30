'use strict';

const express = require('express');

// Constants
const PORT = 5000;

// App
const app = express();
app.get('/', (req, res) => {
  res.send('Hello World');
});

// health check
const health = express();
app.get('/health', (req, res) => {
    res.sendStatus(200);
});

app.listen(PORT, function () {
    console.log(`Running on http://localhost:${PORT}`);
    });

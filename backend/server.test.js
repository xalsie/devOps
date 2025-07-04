const request = require('supertest');
const express = require('express');
const app = express();
app.use(express.json());
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    environment: 'test'
  });
});
app.get('/api/users', (req, res) => {
  res.status(200).json([
    { id: 1, name: 'Test User', email: 'test@example.com' }
  ]);
});
describe('Backend API Tests', () => {
  test('GET /health should return OK status', async () => {
    const response = await request(app)
      .get('/health')
      .expect(200);
    expect(response.body.status).toBe('OK');
    expect(response.body.timestamp).toBeDefined();
  });
  test('GET /api/users should return users array', async () => {
    const response = await request(app)
      .get('/api/users')
      .expect(200);
    expect(Array.isArray(response.body)).toBe(true);
    expect(response.body.length).toBeGreaterThan(0);
  });
});

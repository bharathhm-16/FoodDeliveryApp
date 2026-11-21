import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import apiRoutes from './routes/apiRoutes.js';

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

// Main API Routes
app.use('/api', apiRoutes);

app.get('/', (req, res) => {
  res.json({ message: "Welcome to Food Delivery API! 🚀" });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`=================================================`);
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`=================================================`);
});
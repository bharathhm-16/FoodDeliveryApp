import express from 'express';
import { getAllRestaurants, getRestaurantMenu } from '../controllers/restaurantController.js';

const router = express.Router();

// GET: /api/restaurants (Ella restaurants na thegoluvudu)
router.get('/', getAllRestaurants);

// GET: /api/restaurants/:id/menu (Onu restaurant na menu thegoluvudu)
router.get('/:id/menu', getRestaurantMenu);

export default router;
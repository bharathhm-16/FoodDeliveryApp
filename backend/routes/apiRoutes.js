import express from 'express';
import { register, login } from '../controllers/authController.js';
import { getAllRestaurants, getRestaurantMenu, getCategories, addMenuItem } from '../controllers/restaurantController.js';
import { placeOrder, getMyOrders, getOrderDetails, getAllOrders, updateOrderStatus, getAgentOrders, markAsDelivered, validateCoupon, updateAgentLocation, getAgentLocation } from '../controllers/orderController.js'; 
import { getDashboardStats, getAllUsers, getChartData, addRestaurant } from '../controllers/adminController.js'; // Hosa addRestaurant import
import { addReview, getRestaurantReviews } from '../controllers/reviewController.js'; 
import { toggleFavorite, getMyFavorites } from '../controllers/favoriteController.js'; 
import { getMyAddresses, addAddress, deleteAddress } from '../controllers/addressController.js'; 
import { getProfile, updateProfile } from '../controllers/userController.js'; 
import { verifyToken, verifyRole } from '../middleware/auth.js';

const router = express.Router();

// Auth
router.post('/auth/register', register);
router.post('/auth/login', login);

// User Profile
router.get('/users/profile', verifyToken, getProfile); 
router.put('/users/profile', verifyToken, updateProfile); 

// Restaurants & Menus
router.get('/restaurants', getAllRestaurants);
router.get('/restaurants/:id/menu', getRestaurantMenu);
router.get('/restaurants/:id/reviews', getRestaurantReviews); 

// Orders
router.post('/orders/validate-coupon', verifyToken, validateCoupon); 
router.post('/orders', verifyToken, placeOrder);
router.get('/orders/my', verifyToken, getMyOrders);
router.get('/orders/:id', verifyToken, getOrderDetails);
router.post('/orders/location', verifyToken, updateAgentLocation); 
router.get('/orders/:orderId/agent-location', verifyToken, getAgentLocation); 

// Reviews
router.post('/reviews', verifyToken, addReview); 

// Favorites
router.post('/favorites', verifyToken, toggleFavorite); 
router.get('/favorites', verifyToken, getMyFavorites); 

// Addresses
router.get('/addresses', verifyToken, getMyAddresses); 
router.post('/addresses', verifyToken, addAddress); 
router.delete('/addresses/:id', verifyToken, deleteAddress); 

// Manager Routes
router.get('/manager/orders', verifyToken, verifyRole(['RESTAURANT_MANAGER', 'ADMIN']), getAllOrders);
router.put('/manager/orders/:id/status', verifyToken, verifyRole(['RESTAURANT_MANAGER', 'ADMIN']), updateOrderStatus);
router.get('/manager/categories', verifyToken, verifyRole(['RESTAURANT_MANAGER', 'ADMIN']), getCategories);
router.post('/manager/menu/add', verifyToken, verifyRole(['RESTAURANT_MANAGER', 'ADMIN']), addMenuItem);

// Delivery Agent Routes
router.get('/agent/orders', verifyToken, verifyRole(['DELIVERY_AGENT', 'ADMIN']), getAgentOrders);
router.put('/agent/orders/:id/deliver', verifyToken, verifyRole(['DELIVERY_AGENT', 'ADMIN']), markAsDelivered);

// Admin Routes
router.get('/admin/stats', verifyToken, verifyRole(['ADMIN']), getDashboardStats);
router.get('/admin/users', verifyToken, verifyRole(['ADMIN']), getAllUsers);
router.get('/admin/charts', verifyToken, verifyRole(['ADMIN']), getChartData); 
router.post('/admin/restaurants', verifyToken, verifyRole(['ADMIN']), addRestaurant); // Hosa Route add madide

export default router;
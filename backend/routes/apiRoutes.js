import express from 'express';

import { register, login } from '../controllers/authController.js';

import {
  getAllRestaurants,
  getRestaurantMenu,
  getCategories,
  addMenuItem
} from '../controllers/restaurantController.js';

import {
  placeOrder,
  getMyOrders,
  getOrderDetails,
  getAllOrders,
  updateOrderStatus,
  getAgentOrders,
  markAsDelivered,
  validateCoupon,
  updateAgentLocation,
  getAgentLocation
} from '../controllers/orderController.js';

import {
  getDashboardStats,
  getAllUsers,
  getChartData,
  addRestaurant,
  getAdminRestaurants,
  updateRestaurant,
  updateRestaurantStatus,
  getAdminManagers,
  addManager,
  updateManager
} from '../controllers/adminController.js';

import {
  addReview,
  getRestaurantReviews
} from '../controllers/reviewController.js';

import {
  toggleFavorite,
  getMyFavorites
} from '../controllers/favoriteController.js';

import {
  getMyAddresses,
  addAddress,
  deleteAddress
} from '../controllers/addressController.js';

import {
  getProfile,
  updateProfile,
  changePassword
} from '../controllers/userController.js';

import {
  verifyToken,
  verifyRole
} from '../middleware/auth.js';

const router = express.Router();

// ==========================================
// AUTH ROUTES
// ==========================================

router.post('/auth/register', register);
router.post('/auth/login', login);

// ==========================================
// USER PROFILE ROUTES
// ==========================================

router.get('/users/profile', verifyToken, getProfile);
router.put('/users/profile', verifyToken, updateProfile);
router.put('/users/change-password', verifyToken, changePassword);

// ==========================================
// RESTAURANT & MENU ROUTES
// ==========================================

router.get('/restaurants', getAllRestaurants);
router.get('/restaurants/:id/menu', getRestaurantMenu);
router.get('/restaurants/:id/reviews', getRestaurantReviews);

// ==========================================
// ORDER ROUTES
// ==========================================

router.post('/orders/validate-coupon', verifyToken, validateCoupon);
router.post('/orders', verifyToken, placeOrder);
router.get('/orders/my', verifyToken, getMyOrders);
router.get('/orders/:id', verifyToken, getOrderDetails);
router.post('/orders/location', verifyToken, updateAgentLocation);
router.get('/orders/:orderId/agent-location', verifyToken, getAgentLocation);

// ==========================================
// REVIEW ROUTES
// ==========================================

router.post('/reviews', verifyToken, addReview);

// ==========================================
// FAVORITE ROUTES
// ==========================================

router.post('/favorites', verifyToken, toggleFavorite);
router.get('/favorites', verifyToken, getMyFavorites);

// ==========================================
// ADDRESS ROUTES
// ==========================================

router.get('/addresses', verifyToken, getMyAddresses);
router.post('/addresses', verifyToken, addAddress);
router.delete('/addresses/:id', verifyToken, deleteAddress);

// ==========================================
// RESTAURANT MANAGER ROUTES
// ==========================================

router.get(
  '/manager/orders',
  verifyToken,
  verifyRole(['RESTAURANT_MANAGER', 'ADMIN']),
  getAllOrders
);

router.put(
  '/manager/orders/:id/status',
  verifyToken,
  verifyRole(['RESTAURANT_MANAGER', 'ADMIN']),
  updateOrderStatus
);

router.get(
  '/manager/categories',
  verifyToken,
  verifyRole(['RESTAURANT_MANAGER', 'ADMIN']),
  getCategories
);

router.post(
  '/manager/menu/add',
  verifyToken,
  verifyRole(['RESTAURANT_MANAGER', 'ADMIN']),
  addMenuItem
);

// ==========================================
// DELIVERY AGENT ROUTES
// ==========================================

router.get(
  '/agent/orders',
  verifyToken,
  verifyRole(['DELIVERY_AGENT', 'ADMIN']),
  getAgentOrders
);

router.put(
  '/agent/orders/:id/deliver',
  verifyToken,
  verifyRole(['DELIVERY_AGENT', 'ADMIN']),
  markAsDelivered
);

// ==========================================
// ADMIN DASHBOARD ROUTES
// ==========================================

// Dashboard
router.get(
  '/admin/stats',
  verifyToken,
  verifyRole(['ADMIN']),
  getDashboardStats
);

router.get(
  '/admin/users',
  verifyToken,
  verifyRole(['ADMIN']),
  getAllUsers
);

router.get(
  '/admin/charts',
  verifyToken,
  verifyRole(['ADMIN']),
  getChartData
);

// Restaurant Management
router.get(
  '/admin/restaurants',
  verifyToken,
  verifyRole(['ADMIN']),
  getAdminRestaurants
);

router.post(
  '/admin/restaurants',
  verifyToken,
  verifyRole(['ADMIN']),
  addRestaurant
);

router.put(
  '/admin/restaurants/:id',
  verifyToken,
  verifyRole(['ADMIN']),
  updateRestaurant
);

router.patch(
  '/admin/restaurants/:id/status',
  verifyToken,
  verifyRole(['ADMIN']),
  updateRestaurantStatus
);

// ==========================================
// ADMIN MANAGER MANAGEMENT ROUTES
// ==========================================

router.get(
  '/admin/managers',
  verifyToken,
  verifyRole(['ADMIN']),
  getAdminManagers
);

router.post(
  '/admin/managers',
  verifyToken,
  verifyRole(['ADMIN']),
  addManager
);

router.patch(
  '/admin/managers/:id',
  verifyToken,
  verifyRole(['ADMIN']),
  updateManager
);

// ==========================================
// EXPORT ROUTER
// ==========================================

export default router;
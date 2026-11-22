import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

// 1. Admin Dashboard Statistics
export const getDashboardStats = async (req, res) => {
  try {
    const [
      totalUsers,
      totalCustomers,
      totalManagers,
      totalDeliveryAgents,
      activeUsers,
      totalOrders,
      totalRestaurants,
      revenueResult,
      pendingOrders,
      deliveredOrders,
      cancelledOrders
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { role: 'CUSTOMER' } }),
      prisma.user.count({ where: { role: 'RESTAURANT_MANAGER' } }),
      prisma.user.count({ where: { role: 'DELIVERY_AGENT' } }),
      prisma.user.count({ where: { isActive: true } }),
      prisma.order.count(),
      prisma.restaurant.count(),
      prisma.payment.aggregate({
        where: { status: 'SUCCESS' },
        _sum: { amount: true }
      }),
      prisma.order.count({
        where: {
          status: {
            in: [
              'PLACED',
              'RESTAURANT_ACCEPTED',
              'PREPARING',
              'READY_FOR_PICKUP',
              'AGENT_ASSIGNED',
              'PICKED_UP',
              'OUT_FOR_DELIVERY'
            ]
          }
        }
      }),
      prisma.order.count({ where: { status: 'DELIVERED' } }),
      prisma.order.count({ where: { status: 'CANCELLED' } })
    ]);

    const totalRevenue = Number(revenueResult._sum.amount || 0);

    res.status(200).json({
      totalUsers,
      totalCustomers,
      totalManagers,
      totalDeliveryAgents,
      activeUsers,
      totalOrders,
      totalRestaurants,
      totalRevenue,
      pendingOrders,
      deliveredOrders,
      cancelledOrders
    });
  } catch (error) {
    console.error('Dashboard Stats Error:', error);
    res.status(500).json({ message: 'Error fetching stats' });
  }
};

// 2. Get All Users
export const getAllUsers = async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        fullName: true,
        phone: true,
        role: true,
        isActive: true,
        createdAt: true
      },
      orderBy: { createdAt: 'desc' }
    });

    res.status(200).json(users);
  } catch (error) {
    console.error('Get Users Error:', error);
    res.status(500).json({ message: 'Error fetching users' });
  }
};

// 3. Dashboard Chart Data
export const getChartData = async (req, res) => {
  try {
    const statuses = [
      'PLACED',
      'RESTAURANT_ACCEPTED',
      'PREPARING',
      'READY_FOR_PICKUP',
      'AGENT_ASSIGNED',
      'PICKED_UP',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
      'CANCELLED'
    ];

    const statusCounts = await Promise.all(
      statuses.map(async (status) => ({
        status,
        count: await prisma.order.count({
          where: { status }
        })
      }))
    );

    const orderStatus = Object.fromEntries(
      statusCounts.map(item => [item.status, item.count])
    );

    const successfulPayments = await prisma.payment.findMany({
      where: { status: 'SUCCESS' },
      select: {
        amount: true,
        order: {
          select: {
            restaurant: {
              select: { name: true }
            }
          }
        }
      }
    });

    const revenueMap = new Map();

    for (const payment of successfulPayments) {
      const restaurantName = payment.order.restaurant.name;
      const amount = Number(payment.amount);

      revenueMap.set(
        restaurantName,
        (revenueMap.get(restaurantName) || 0) + amount
      );
    }

    const revenueByRestaurant = Array.from(
      revenueMap,
      ([name, revenue]) => ({ name, revenue })
    ).sort((a, b) => b.revenue - a.revenue);

    res.status(200).json({
      orderStatus,
      revenueByRestaurant
    });
  } catch (error) {
    console.error('Chart Data Error:', error);
    res.status(500).json({ message: 'Error fetching chart data' });
  }
};

// 4. Add Restaurant
export const addRestaurant = async (req, res) => {
  try {
    const {
      name,
      cuisineType,
      addressLine,
      city,
      imageUrl,
      latitude,
      longitude
    } = req.body;

    if (
      !name || typeof name !== 'string' ||
      !addressLine || typeof addressLine !== 'string' ||
      !city || typeof city !== 'string'
    ) {
      return res.status(400).json({
        message: 'Restaurant name, address and city are required'
      });
    }

    const lat =
      latitude === undefined || latitude === null || latitude === ''
        ? null
        : Number(latitude);

    const lng =
      longitude === undefined || longitude === null || longitude === ''
        ? null
        : Number(longitude);

    if (
      (lat !== null && (!Number.isFinite(lat) || lat < -90 || lat > 90)) ||
      (lng !== null && (!Number.isFinite(lng) || lng < -180 || lng > 180))
    ) {
      return res.status(400).json({
        message: 'Please provide valid latitude and longitude'
      });
    }

    if ((lat === null) !== (lng === null)) {
      return res.status(400).json({
        message: 'Provide both latitude and longitude, or leave both empty'
      });
    }

    const restaurant = await prisma.restaurant.create({
      data: {
        name: name.trim(),
        cuisineType: cuisineType || null,
        addressLine: addressLine.trim(),
        city: city.trim(),
        imageUrl:
          imageUrl ||
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80',
        latitude: lat,
        longitude: lng,
        categories: {
          create: [{ name: 'Recommended' }]
        }
      }
    });

    res.status(201).json({
      message: 'Restaurant added successfully!',
      restaurant
    });
  } catch (error) {
    console.error('Add Restaurant Error:', error);
    res.status(500).json({ message: 'Error adding restaurant' });
  }
};

// 5. Admin: Get All Restaurants (Open + Closed)
export const getAdminRestaurants = async (req, res) => {
  try {
    const restaurants = await prisma.restaurant.findMany({
      include: {
        manager: {
          include: {
            user: {
              select: {
                id: true,
                fullName: true,
                email: true,
                phone: true,
                isActive: true
              }
            }
          }
        },
        _count: {
          select: {
            orders: true,
            reviews: true
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.status(200).json(restaurants);
  } catch (error) {
    console.error('Admin Restaurants Error:', error);
    res.status(500).json({ message: 'Error fetching restaurants' });
  }
};

// 6. Admin: Update Restaurant Details
export const updateRestaurant = async (req, res) => {
  try {
    const id = Number(req.params.id);

    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({ message: 'Invalid restaurant ID' });
    }

    const {
      name,
      cuisineType,
      addressLine,
      city,
      imageUrl,
      latitude,
      longitude
    } = req.body;

    const existing = await prisma.restaurant.findUnique({
      where: { id }
    });

    if (!existing) {
      return res.status(404).json({ message: 'Restaurant not found' });
    }

    const data = {};

    if (name !== undefined) {
      if (typeof name !== 'string' || !name.trim()) {
        return res.status(400).json({ message: 'Invalid restaurant name' });
      }
      data.name = name.trim();
    }

    if (cuisineType !== undefined) {
      data.cuisineType = cuisineType || null;
    }

    if (addressLine !== undefined) {
      if (typeof addressLine !== 'string' || !addressLine.trim()) {
        return res.status(400).json({ message: 'Invalid address' });
      }
      data.addressLine = addressLine.trim();
    }

    if (city !== undefined) {
      if (typeof city !== 'string' || !city.trim()) {
        return res.status(400).json({ message: 'Invalid city' });
      }
      data.city = city.trim();
    }

    if (imageUrl !== undefined) {
      data.imageUrl = imageUrl || null;
    }

    const lat = latitude === undefined
      ? existing.latitude === null ? null : Number(existing.latitude)
      : latitude === null || latitude === '' ? null : Number(latitude);

    const lng = longitude === undefined
      ? existing.longitude === null ? null : Number(existing.longitude)
      : longitude === null || longitude === '' ? null : Number(longitude);

    if (
      (lat !== null && (!Number.isFinite(lat) || lat < -90 || lat > 90)) ||
      (lng !== null && (!Number.isFinite(lng) || lng < -180 || lng > 180))
    ) {
      return res.status(400).json({ message: 'Invalid coordinates' });
    }

    if ((lat === null) !== (lng === null)) {
      return res.status(400).json({
        message: 'Provide both latitude and longitude, or leave both empty'
      });
    }

    if (latitude !== undefined || longitude !== undefined) {
      data.latitude = lat;
      data.longitude = lng;
    }

    const restaurant = await prisma.restaurant.update({
      where: { id },
      data
    });

    res.status(200).json({
      message: 'Restaurant updated successfully',
      restaurant
    });
  } catch (error) {
    console.error('Update Restaurant Error:', error);
    res.status(500).json({ message: 'Error updating restaurant' });
  }
};

// 7. Admin: Open / Close Restaurant
export const updateRestaurantStatus = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { isOpen } = req.body;

    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({ message: 'Invalid restaurant ID' });
    }

    if (typeof isOpen !== 'boolean') {
      return res.status(400).json({
        message: 'isOpen must be true or false'
      });
    }

    const existing = await prisma.restaurant.findUnique({
      where: { id },
      select: { id: true }
    });

    if (!existing) {
      return res.status(404).json({ message: 'Restaurant not found' });
    }

    const restaurant = await prisma.restaurant.update({
      where: { id },
      data: { isOpen }
    });

    res.status(200).json({
      message: isOpen
        ? 'Restaurant opened successfully'
        : 'Restaurant closed successfully',
      restaurant
    });
  } catch (error) {
    console.error('Restaurant Status Error:', error);
    res.status(500).json({ message: 'Error updating restaurant status' });
  }
};

// ==========================================
// ADMIN MANAGER MANAGEMENT
// ==========================================

// GET ALL MANAGERS
export const getAdminManagers = async (req, res) => {
  try {
    const managers = await prisma.restaurantManager.findMany({
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
            role: true,
            isActive: true,
            createdAt: true
          }
        },
        restaurant: true
      },
      orderBy: {
        id: 'desc'
      }
    });

    return res.status(200).json({
      count: managers.length,
      managers
    });
  } catch (error) {
    console.error('Get managers error:', error);
    return res.status(500).json({
      message: 'Failed to fetch managers'
    });
  }
};


// ADD NEW MANAGER
export const addManager = async (req, res) => {
  try {
    const {
      fullName,
      email,
      phone,
      password,
      restaurantId
    } = req.body;

    if (!fullName || !email || !password || !restaurantId) {
      return res.status(400).json({
        message: 'Full name, email, password and restaurant are required'
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        message: 'Password must contain at least 8 characters'
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const selectedRestaurantId = Number(restaurantId);

    if (
      !Number.isInteger(selectedRestaurantId) ||
      selectedRestaurantId <= 0
    ) {
      return res.status(400).json({
        message: 'Invalid restaurant ID'
      });
    }

    const existingUser = await prisma.user.findUnique({
      where: {
        email: normalizedEmail
      }
    });

    if (existingUser) {
      return res.status(409).json({
        message: 'Email is already registered'
      });
    }

    const restaurant = await prisma.restaurant.findUnique({
      where: {
        id: selectedRestaurantId
      }
    });

    if (!restaurant) {
      return res.status(404).json({
        message: 'Restaurant not found'
      });
    }

    const existingManager = await prisma.restaurantManager.findUnique({
      where: {
        restaurantId: selectedRestaurantId
      }
    });

    if (existingManager) {
      return res.status(409).json({
        message: 'This restaurant already has an assigned manager'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const manager = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          fullName: fullName.trim(),
          email: normalizedEmail,
          phone: phone || null,
          passwordHash: hashedPassword,
          role: 'RESTAURANT_MANAGER',
          isActive: true
        }
      });

      const managerRecord = await tx.restaurantManager.create({
        data: {
          userId: user.id,
          restaurantId: selectedRestaurantId
        },
        include: {
          user: {
            select: {
              id: true,
              fullName: true,
              email: true,
              phone: true,
              role: true,
              isActive: true,
              createdAt: true
            }
          },
          restaurant: true
        }
      });

      return managerRecord;
    });

    return res.status(201).json({
      message: 'Manager created and restaurant assigned successfully',
      manager
    });

  } catch (error) {
    console.error('Add manager error:', error);

    if (error.code === 'P2002') {
      return res.status(409).json({
        message: 'Email or restaurant already has an assignment'
      });
    }

    return res.status(500).json({
      message: 'Failed to create manager'
    });
  }
};
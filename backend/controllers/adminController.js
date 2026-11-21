import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

// 1. Admin Dashboard ge Statistics thegoluvudu
export const getDashboardStats = async (req, res) => {
  try {
    const totalUsers = await prisma.user.count();
    const totalOrders = await prisma.order.count();
    const totalRestaurants = await prisma.restaurant.count();
    
    const orders = await prisma.order.findMany({
      where: { status: 'DELIVERED' }
    });
    const totalRevenue = orders.reduce((sum, order) => sum + Number(order.totalAmount), 0);

    res.status(200).json({
      totalUsers,
      totalOrders,
      totalRestaurants,
      totalRevenue
    });
  } catch (error) {
    res.status(500).json({ message: "Error fetching stats" });
  }
};

// 2. Ella Users na thegoluvudu
export const getAllUsers = async (req, res) => {
  try {
    const users = await prisma.user.findMany({ orderBy: { createdAt: 'desc' } });
    const safeUsers = users.map(user => {
      const { passwordHash, ...safeUser } = user;
      return safeUser;
    });
    res.status(200).json(safeUsers);
  } catch (error) {
    res.status(500).json({ message: "Error fetching users" });
  }
};

// 3. Chart Data thegoluvudu
export const getChartData = async (req, res) => {
  try {
    const placed = await prisma.order.count({ where: { status: 'PLACED' } });
    const preparing = await prisma.order.count({ where: { status: 'PREPARING' } });
    const outForDelivery = await prisma.order.count({ where: { status: 'OUT_FOR_DELIVERY' } });
    const delivered = await prisma.order.count({ where: { status: 'DELIVERED' } });

    const restaurants = await prisma.restaurant.findMany({
      include: { orders: { where: { status: 'DELIVERED' } } }
    });

    const revenueByRestaurant = restaurants.map(rest => {
      const revenue = rest.orders.reduce((sum, order) => sum + Number(order.totalAmount), 0);
      return { name: rest.name, revenue };
    });

    res.status(200).json({
      orderStatus: { placed, preparing, outForDelivery, delivered },
      revenueByRestaurant
    });
  } catch (error) {
    res.status(500).json({ message: "Error fetching chart data" });
  }
};

// 4. HOSA: Admin Hosa Restaurant Add Madalu
export const addRestaurant = async (req, res) => {
  try {
    const { name, cuisineType, addressLine, city, imageUrl } = req.body;

    // Default aagi Mumbai location kottidivi (Map alli kanalu)
    const lat = 19.0760 + (Math.random() * 0.1 - 0.05);
    const lng = 72.8777 + (Math.random() * 0.1 - 0.05);

    const restaurant = await prisma.restaurant.create({
      data: {
        name,
        cuisineType,
        addressLine,
        city,
        imageUrl: imageUrl || 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80', // Default image
        latitude: lat,
        longitude: lng,
        categories: {
          create: [
            {
              name: 'Recommended', // Default category
            }
          ]
        }
      }
    });

    res.status(201).json({ message: "Restaurant added successfully! 🎉", restaurant });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error adding restaurant" });
  }
};
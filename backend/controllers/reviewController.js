import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

// 1. Customer Review Add Madalu
export const addReview = async (req, res) => {
  try {
    const { orderId, rating, comment } = req.body;
    const userId = req.user.userId;

    // Customer ID thegoluvudu
    const customer = await prisma.customer.findUnique({ where: { userId } });
    if (!customer) return res.status(404).json({ message: "Customer not found" });

    // Order thegoluvudu
    const order = await prisma.order.findUnique({ where: { id: parseInt(orderId) } });
    if (!order) return res.status(404).json({ message: "Order not found" });

    // Already Review madidira antha check maduvudu
    const existingReview = await prisma.review.findUnique({ where: { orderId: parseInt(orderId) } });
    if (existingReview) return res.status(400).json({ message: "You already reviewed this order!" });

    // Review Create maduvudu
    const review = await prisma.review.create({
      data: {
        customerId: customer.id,
        restaurantId: order.restaurantId,
        orderId: parseInt(orderId),
        rating: parseInt(rating),
        comment
      }
    });

    res.status(201).json({ message: "Review added successfully! 🎉", review });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error adding review" });
  }
};

// 2. Restaurant ge bandiruva Reviews na thegoluvudu
export const getRestaurantReviews = async (req, res) => {
  try {
    const { id } = req.params;
    const reviews = await prisma.review.findMany({
      where: { restaurantId: parseInt(id) },
      include: { 
        customer: { include: { user: true } } 
      },
      orderBy: { createdAt: 'desc' }
    });
    
    // Password hide maduvudu
    const safeReviews = reviews.map(r => {
       if (r.customer && r.customer.user) {
           const { passwordHash, ...safeUser } = r.customer.user;
           r.customer.user = safeUser;
       }
       return r;
    });
    
    res.status(200).json(safeReviews);
  } catch (error) {
    res.status(500).json({ message: "Error fetching reviews" });
  }
};
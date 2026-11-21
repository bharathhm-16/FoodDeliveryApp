import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

// 1. HOSA: Coupon Validate Madalu
export const validateCoupon = async (req, res) => {
  try {
    const { code, subtotal } = req.body;

    const coupon = await prisma.coupon.findUnique({ where: { code: code } });

    if (!coupon || !coupon.isActive) {
      return res.status(400).json({ message: "Invalid or expired coupon code" });
    }

    if (subtotal < coupon.minOrderAmount) {
      return res.status(400).json({ message: `Minimum order amount is ₹${coupon.minOrderAmount}` });
    }

    const discountAmount = (subtotal * coupon.discountPercent) / 100;

    res.status(200).json({
      message: "Coupon applied! 🎉",
      discountPercent: coupon.discountPercent,
      discountAmount: discountAmount
    });
  } catch (error) {
    res.status(500).json({ message: "Error validating coupon" });
  }
};

// 2. Order Place Maduvudu (Discount logic jothe)
export const placeOrder = async (req, res) => {
  try {
    const { restaurantId, items, totalAmount, paymentMethod, couponCode } = req.body;
    const userId = req.user.userId; 
    
    let customer = await prisma.customer.findUnique({ where: { userId } });
    if (!customer) customer = await prisma.customer.create({ data: { userId } });

    let address = await prisma.address.findFirst({ where: { customerId: customer.id } });
    if (!address) {
      address = await prisma.address.create({
        data: { customerId: customer.id, addressLine: 'Default Address', city: 'Mumbai', isDefault: true }
      });
    }

    const orderNumber = 'ORD-' + Date.now();
    const parsedTotal = parseFloat(totalAmount);
    const deliveryFee = 40.0;
    
    let discountAmount = 0;
    let validCouponCode = null;

    // Coupon ideya illva antha check maduvudu
    if (couponCode) {
      const coupon = await prisma.coupon.findUnique({ where: { code: couponCode } });
      if (coupon && coupon.isActive && parsedTotal >= coupon.minOrderAmount) {
        discountAmount = (parsedTotal * coupon.discountPercent) / 100;
        validCouponCode = coupon.code;
      }
    }

    // Final Amount = (Subtotal + Delivery) - Discount
    const finalTotal = (parsedTotal + deliveryFee) - discountAmount;

    const order = await prisma.order.create({
      data: {
        orderNumber,
        customerId: userId, 
        restaurantId: parseInt(restaurantId),
        subtotal: parsedTotal,
        deliveryFee: deliveryFee,
        discountAmount: discountAmount,
        totalAmount: finalTotal,
        couponCode: validCouponCode,
        items: {
          create: items.map(item => ({
            foodItemId: parseInt(item.id),
            itemName: item.name, 
            quantity: parseInt(item.quantity),
            unitPrice: parseFloat(item.price),
            lineTotal: parseFloat(item.price) * parseInt(item.quantity)
          }))
        },
        payment: {
          create: {
            method: paymentMethod || 'CASH_ON_DELIVERY',
            status: paymentMethod === 'UPI' ? 'SUCCESS' : 'PENDING', 
            amount: finalTotal
          }
        }
      }
    });

    res.status(201).json({ message: "Order placed successfully!", orderId: order.id });
  } catch (error) {
    console.error("Order Error Details:", error); 
    res.status(500).json({ message: "Error placing order" });
  }
};

export const getMyOrders = async (req, res) => {
  try {
    const userId = req.user.userId;
    const orders = await prisma.order.findMany({
      where: { customerId: userId },
      include: { restaurant: true, items: true, payment: true },
      orderBy: { placedAt: 'desc' }
    });
    res.status(200).json(orders);
  } catch (error) {
    res.status(500).json({ message: "Error fetching orders" });
  }
};

export const getOrderDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const order = await prisma.order.findUnique({
      where: { id: parseInt(id) },
      include: { restaurant: true, items: true, payment: true }
    });
    res.status(200).json(order);
  } catch (error) {
    res.status(500).json({ message: "Error fetching order details" });
  }
};

export const getAllOrders = async (req, res) => {
  try {
    const orders = await prisma.order.findMany({
      include: { restaurant: true, items: true, customer: true, payment: true },
      orderBy: { placedAt: 'desc' }
    });
    res.status(200).json(orders);
  } catch (error) {
    res.status(500).json({ message: "Error fetching all orders" });
  }
};

export const updateOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body; 
    const order = await prisma.order.update({
      where: { id: parseInt(id) },
      data: { status: status }
    });
    res.status(200).json({ message: "Status updated!", order });
  } catch (error) {
    res.status(500).json({ message: "Error updating status" });
  }
};

export const getAgentOrders = async (req, res) => {
  try {
    const orders = await prisma.order.findMany({
      where: { status: 'OUT_FOR_DELIVERY' },
      include: { restaurant: true, items: true, customer: true, payment: true },
      orderBy: { placedAt: 'asc' }
    });
    res.status(200).json(orders);
  } catch (error) {
    res.status(500).json({ message: "Error fetching agent orders" });
  }
};

export const markAsDelivered = async (req, res) => {
  try {
    const { id } = req.params;
    
    const order = await prisma.order.update({
      where: { id: parseInt(id) },
      data: { status: 'DELIVERED' }
    });

    await prisma.payment.updateMany({
      where: { orderId: parseInt(id), method: 'CASH_ON_DELIVERY', status: 'PENDING' },
      data: { status: 'SUCCESS' }
    });

    res.status(200).json({ message: "Order Delivered successfully!", order });
  } catch (error) {
    res.status(500).json({ message: "Error updating delivery status" });
  }
};

// HOSA: Agent Location Update Madalu
export const updateAgentLocation = async (req, res) => {
  try {
    const { orderId, lat, lng } = req.body;
    
    // Order ideya illva antha check madodu
    const order = await prisma.order.findUnique({ where: { id: parseInt(orderId) } });
    if (!order) return res.status(404).json({ message: "Order not found" });

    // DeliveryAssignment ideya illva check madodu
    let assignment = await prisma.deliveryAssignment.findUnique({ where: { orderId: parseInt(orderId) } });
    
    if (!assignment) {
      // Assignment illandre, hosa create madodu
      const agent = await prisma.deliveryAgent.findFirst(); // Test ge modala agent na thegoluvudu
      if (!agent) return res.status(404).json({ message: "No agents available" });
      
      assignment = await prisma.deliveryAssignment.create({
        data: { orderId: parseInt(orderId), agentId: agent.id, status: 'IN_TRANSIT' }
      });
    }

    // Location history ge save madodu
    await prisma.deliveryLocationHistory.create({
      data: {
        assignmentId: assignment.id,
        latitude: parseFloat(lat),
        longitude: parseFloat(lng)
      }
    });

    // Agent avara current location update madodu
    await prisma.deliveryAgent.update({
      where: { id: assignment.agentId },
      data: { currentLat: parseFloat(lat), currentLng: parseFloat(lng) }
    });

    res.status(200).json({ message: "Location updated" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error updating location" });
  }
};

// HOSA: Customer ge Agent Location thegolalu
export const getAgentLocation = async (req, res) => {
  try {
    const { orderId } = req.params;
    
    const assignment = await prisma.deliveryAssignment.findUnique({
      where: { orderId: parseInt(orderId) },
      include: { 
        agent: { include: { user: true } },
        locations: { orderBy: { recordedAt: 'desc' }, take: 1 } // Latest location
      }
    });

    if (!assignment) {
      return res.status(404).json({ message: "Agent not assigned yet" });
    }

    const latestLocation = assignment.locations.length > 0 ? assignment.locations[0] : null;
    
    res.status(200).json({
      agentName: assignment.agent.user.fullName,
      agentPhone: assignment.agent.user.phone,
      lat: latestLocation ? latestLocation.latitude : assignment.agent.currentLat,
      lng: latestLocation ? latestLocation.longitude : assignment.agent.currentLng
    });
  } catch (error) {
    res.status(500).json({ message: "Error fetching agent location" });
  }
};
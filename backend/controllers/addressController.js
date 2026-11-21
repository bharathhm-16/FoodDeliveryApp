import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

// 1. Customer avara Ella Address thegoluvudu
export const getMyAddresses = async (req, res) => {
  try {
    const userId = req.user.userId;
    const customer = await prisma.customer.findUnique({ where: { userId } });
    if (!customer) return res.status(404).json({ message: "Customer not found" });

    const addresses = await prisma.address.findMany({
      where: { customerId: customer.id },
      orderBy: { isDefault: 'desc' }
    });
    res.status(200).json(addresses);
  } catch (error) {
    res.status(500).json({ message: "Error fetching addresses" });
  }
};

// 2. Hosa Address Add Maduvudu
export const addAddress = async (req, res) => {
  try {
    const { label, addressLine, city, postalCode, latitude, longitude, isDefault } = req.body;
    const userId = req.user.userId;
    
    const customer = await prisma.customer.findUnique({ where: { userId } });
    if (!customer) return res.status(404).json({ message: "Customer not found" });

    // Ondu address default aagbeku antha kottidre, hale default na remove maduvudu
    if (isDefault) {
      await prisma.address.updateMany({
        where: { customerId: customer.id, isDefault: true },
        data: { isDefault: false }
      });
    }

    const address = await prisma.address.create({
      data: {
        customerId: customer.id,
        label: label || 'Home',
        addressLine,
        city,
        postalCode,
        latitude: latitude ? parseFloat(latitude) : null,
        longitude: longitude ? parseFloat(longitude) : null,
        isDefault: isDefault || false
      }
    });

    res.status(201).json({ message: "Address added successfully! 🎉", address });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error adding address" });
  }
};

// 3. Address Delete Maduvudu
export const deleteAddress = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.address.delete({ where: { id: parseInt(id) } });
    res.status(200).json({ message: "Address deleted" });
  } catch (error) {
    res.status(500).json({ message: "Error deleting address" });
  }
};
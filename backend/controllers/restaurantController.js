import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

export const getAllRestaurants = async (req, res) => {
  try {
    const restaurants = await prisma.restaurant.findMany({ where: { isOpen: true } });
    res.status(200).json(restaurants);
  } catch (error) {
    res.status(500).json({ message: "Error fetching restaurants" });
  }
};

export const getRestaurantMenu = async (req, res) => {
  try {
    const { id } = req.params;
    const restaurant = await prisma.restaurant.findUnique({
      where: { id: parseInt(id) },
      include: {
        categories: { include: { items: { include: { images: true } } } }
      }
    });
    res.status(200).json(restaurant);
  } catch (error) {
    res.status(500).json({ message: "Error fetching menu" });
  }
};

// HOSA: Manager ge Categories thegolalu
export const getCategories = async (req, res) => {
  try {
    const categories = await prisma.foodCategory.findMany();
    res.status(200).json(categories);
  } catch (error) {
    res.status(500).json({ message: "Error fetching categories" });
  }
};

// HOSA: Manager hosa Food Item add madalu
export const addMenuItem = async (req, res) => {
  try {
    const { name, price, description, categoryId, imageUrl } = req.body;
    
    const item = await prisma.foodItem.create({
      data: {
        name,
        price: parseFloat(price),
        description,
        categoryId: parseInt(categoryId),
        images: {
          create: [{ 
            imageUrl: imageUrl || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80' 
          }]
        }
      }
    });
    
    res.status(201).json({ message: "Item added successfully!", item });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error adding item" });
  }
};
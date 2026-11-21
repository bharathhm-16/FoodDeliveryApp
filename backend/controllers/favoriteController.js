import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

// 1. Favorite Add / Remove Madalu (Toggle)
export const toggleFavorite = async (req, res) => {
  try {
    const { restaurantId } = req.body;
    const userId = req.user.userId;

    // Item already favorite aagideya antha check madodu
    const existingFav = await prisma.favorite.findUnique({
      where: {
        userId_restaurantId: {
          userId: userId,
          restaurantId: parseInt(restaurantId)
        }
      }
    });

    if (existingFav) {
      // Already ide andre, remove madodu
      await prisma.favorite.delete({ where: { id: existingFav.id } });
      return res.status(200).json({ message: "Removed from favorites" });
    } else {
      // Illa andre, hosa favorite create madodu
      await prisma.favorite.create({
        data: {
          userId: userId,
          restaurantId: parseInt(restaurantId)
        }
      });
      return res.status(201).json({ message: "Added to favorites" });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error updating favorite" });
  }
};

// 2. Customer avara Ella Favorites na thegoluvudu
export const getMyFavorites = async (req, res) => {
  try {
    const userId = req.user.userId;
    const favorites = await prisma.favorite.findMany({
      where: { userId: userId },
      include: { restaurant: true } // Restaurant details jothe
    });
    res.status(200).json(favorites);
  } catch (error) {
    res.status(500).json({ message: "Error fetching favorites" });
  }
};
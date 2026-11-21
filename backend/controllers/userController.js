import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

// 1. User Profile thegoluvudu
export const getProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const user = await prisma.user.findUnique({ where: { id: userId } });

    if (!user) return res.status(404).json({ message: "User not found" });

    // Password hash hide maduvudu
    const { passwordHash, ...safeUser } = user;
    res.status(200).json(safeUser);
  } catch (error) {
    res.status(500).json({ message: "Error fetching profile" });
  }
};

// 2. User Profile Update Maduvudu
export const updateProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { fullName, phone } = req.body;

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        fullName: fullName,
        phone: phone
      }
    });

    const { passwordHash, ...safeUser } = updatedUser;
    res.status(200).json({ message: "Profile updated successfully! 🎉", user: safeUser });
  } catch (error) {
    res.status(500).json({ message: "Error updating profile" });
  }
};
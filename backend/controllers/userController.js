import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

// 1. User Profile Get
export const getProfile = async (req, res) => {
  try {
    const userId = req.user.userId;

    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({
        message: "User not found"
      });
    }

    // Hide password hash
    const { passwordHash, ...safeUser } = user;

    res.status(200).json(safeUser);

  } catch (error) {
    console.error("Get profile error:", error.message);

    res.status(500).json({
      message: "Error fetching profile"
    });
  }
};


// 2. User Profile Update
export const updateProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { fullName, phone } = req.body;

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        fullName,
        phone
      }
    });

    const { passwordHash, ...safeUser } = updatedUser;

    res.status(200).json({
      message: "Profile updated successfully! 🎉",
      user: safeUser
    });

  } catch (error) {
    console.error("Update profile error:", error.message);

    res.status(500).json({
      message: "Error updating profile"
    });
  }
};


// 3. Change Password
export const changePassword = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        message: "Current and new passwords are required"
      });
    }

    if (typeof newPassword !== 'string' || newPassword.length < 8 || newPassword.length > 128) {
      return res.status(400).json({
        message: "New password must be between 8 and 128 characters"
      });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({
        message: "User not found"
      });
    }

    const isMatch = await bcrypt.compare(
      currentPassword,
      user.passwordHash
    );

    if (!isMatch) {
      return res.status(400).json({
        message: "Current password is incorrect"
      });
    }

    const isSamePassword = await bcrypt.compare(
      newPassword,
      user.passwordHash
    );

    if (isSamePassword) {
      return res.status(400).json({
        message: "New password must be different from current password"
      });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);

    await prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash: hashedPassword
      }
    });

    res.status(200).json({
      message: "Password changed successfully"
    });

  } catch (error) {
    console.error("Change password error:", error.message);

    res.status(500).json({
      message: "Error changing password"
    });
  }
};
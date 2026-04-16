#!/usr/bin/env tsx
/**
 * Reset password utility
 * Usage: tsx scripts/reset-password.ts email@example.com newpassword
 */

import "dotenv/config";
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcrypt";

const prisma = new PrismaClient();

async function resetPassword(email: string, newPassword: string) {
  try {
    const user = await prisma.user.findUnique({ where: { email } });
    
    if (!user) {
      console.error(`❌ User with email ${email} not found`);
      process.exit(1);
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);
    
    await prisma.user.update({
      where: { email },
      data: { passwordHash }
    });

    console.log(`✅ Password updated for ${email}`);
    console.log(`   You can now log in with this password`);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

const email = process.argv[2];
const password = process.argv[3];

if (!email || !password) {
  console.error("Usage: tsx scripts/reset-password.ts email@example.com newpassword");
  process.exit(1);
}

resetPassword(email, password);


import NextAuth from "next-auth";
import { authOptions } from "@/lib/auth";

const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };

// Ensure Node.js runtime (Prisma + bcrypt are not supported on the Edge runtime)
export const runtime = "nodejs";



/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  transpilePackages: ['lucide-react', 'recharts'],
  images: {
    unoptimized: true,
  },
};

export default nextConfig;

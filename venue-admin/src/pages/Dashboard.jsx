import React, { useState } from "react";
import { motion } from "framer-motion";
import Box from "@mui/joy/Box";
import Card from "@mui/joy/Card";
import Typography from "@mui/joy/Typography";
import Button from "@mui/joy/Button";
import LinearProgress from "@mui/joy/LinearProgress";
import { useNavigate } from "react-router";
import Preloader from "../components/Preloader";

function Dashboard() {
    const [loading, setLoading] = useState(false);

    const navigate = useNavigate();
    const [stats] = useState({
        totalSports: 12,
        activeSessions: 5,
        totalUsers: 248,
        revenue: "$12,500",
    });

    const [recentActivities] = useState([
        {
            id: 1,
            title: "Basketball Court Booked",
            user: "John Doe",
            time: "2 hours ago",
        },
        {
            id: 2,
            title: "New Sport Added - Pickleball",
            user: "Admin",
            time: "5 hours ago",
        },
        {
            id: 3,
            title: "Tennis Court Maintenance",
            user: "Manager",
            time: "1 day ago",
        },
        {
            id: 4,
            title: "Volleyball Event Scheduled",
            user: "Sarah Smith",
            time: "2 days ago",
        },
    ]);

    const [sportMetrics] = useState([
        { name: "Basketball", users: 45, progress: 90 },
        { name: "Football", users: 38, progress: 76 },
        { name: "Tennis", users: 32, progress: 64 },
        { name: "Volleyball", users: 28, progress: 56 },
        { name: "Badminton", users: 25, progress: 50 },
    ]);

    const containerVariants = {
        hidden: { opacity: 0, y: 10 },
        visible: {
            opacity: 1,
            y: 0,
            transition: { duration: 0.5, staggerChildren: 0.1 },
        },
    };

    const itemVariants = {
        hidden: { opacity: 0, y: 10 },
        visible: { opacity: 1, y: 0 },
    };

    if (loading) {
        return (
            <Preloader />
        );
    }

    return (
        <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            style={{ width: "100%", maxWidth: "100%", overflowX: "hidden" }}
        >
            <Box sx={{ p: { xs: 1.5, sm: 2, md: 3 }, maxWidth: "100%", overflowX: "hidden" }}>
                {/* Header Section */}
                <Box sx={{ mb: 3 }}>
                    <Typography level="h1" sx={{ mb: 0.5, fontSize: { xs: "1.5rem", sm: "1.875rem", md: "2.25rem" } }}>
                        Welcome Back, Owner!
                    </Typography>
                    <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                        Here's an overview of your sports management platform
                    </Typography>
                </Box>

                {/* Stats Cards */}
                <motion.div variants={itemVariants}>
                    <Box
                        sx={{
                            display: "grid",
                            gridTemplateColumns: {
                                xs: "1fr",
                                sm: "repeat(2, 1fr)",
                                md: "repeat(4, 1fr)",
                            },
                            gap: { xs: 1.5, sm: 2 },
                            mb: 3,
                        }}
                    >
                        {[
                            {
                                label: "Total Sports",
                                value: stats.totalSports,
                                icon: "⚽",
                                color: "#3b82f6",
                            },
                            {
                                label: "Active Sessions",
                                value: stats.activeSessions,
                                icon: "🎮",
                                color: "#10b981",
                            },
                            {
                                label: "Total Users",
                                value: stats.totalUsers,
                                icon: "👥",
                                color: "#8b5cf6",
                            },
                            {
                                label: "Revenue",
                                value: stats.revenue,
                                icon: "💰",
                                color: "#f59e0b",
                            },
                        ].map((stat, index) => (
                            <motion.div key={index} variants={itemVariants}>
                                <Card
                                    variant="outlined"
                                    sx={{
                                        p: { xs: 1.5, sm: 2 },
                                        backgroundColor: "rgba(255,255,255,0.5)",
                                        backdropFilter: "blur(10px)",
                                        transition: "all 0.3s ease",
                                        "&:hover": {
                                            boxShadow: "0 8px 16px rgba(0,0,0,0.1)",
                                            transform: "translateY(-4px)",
                                        },
                                    }}
                                >
                                    <Box
                                        sx={{
                                            display: "flex",
                                            alignItems: "center",
                                            gap: 1.5,
                                            mb: 1,
                                        }}
                                    >
                                        <Box
                                            sx={{
                                                fontSize: { xs: "1.25rem", sm: "1.5rem" },
                                            }}
                                        >
                                            {stat.icon}
                                        </Box>
                                        <Box sx={{ flex: 1, minWidth: 0 }}>
                                            <Typography level="body-xs" sx={{ color: "neutral.500", mb: 0.5, fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>
                                                {stat.label}
                                            </Typography>
                                            <Typography level="h3" sx={{ fontSize: { xs: "1.125rem", sm: "1.25rem" }, wordBreak: "break-word" }}>
                                                {stat.value}
                                            </Typography>
                                        </Box>
                                    </Box>
                                    <LinearProgress
                                        determinate
                                        value={Math.random() * 30 + 70}
                                        variant="solid"
                                        color="primary"
                                        sx={{ height: 4 }}
                                    />
                                </Card>
                            </motion.div>
                        ))}
                    </Box>
                </motion.div>

                {/* Main Content Grid */}
                <Box
                    sx={{
                        display: "grid",
                        gridTemplateColumns: {
                            xs: "1fr",
                            sm: "1fr",
                            md: "2fr 1fr",
                        },
                        gap: { xs: 2, sm: 2, md: 3 },
                    }}
                >
                    {/* Sports Metrics */}
                    <motion.div variants={itemVariants}>
                        <Card variant="outlined" sx={{ p: { xs: 1.5, sm: 2 } }}>
                            <Typography level="h3" sx={{ mb: 2, fontSize: { xs: "1.125rem", sm: "1.25rem" } }}>
                                Sports Popularity
                            </Typography>
                            <Box sx={{ display: "flex", flexDirection: "column", gap: 2.5 }}>
                                {sportMetrics.map((sport, index) => (
                                    <Box key={index}>
                                        <Box
                                            sx={{
                                                display: "flex",
                                                justifyContent: "space-between",
                                                mb: 0.75,
                                            }}
                                        >
                                            <Typography level="body-sm" sx={{ fontWeight: "md" }}>
                                                {sport.name}
                                            </Typography>
                                            <Typography level="body-xs" sx={{ color: "neutral.500" }}>
                                                {sport.users} users
                                            </Typography>
                                        </Box>
                                        <LinearProgress
                                            determinate
                                            value={sport.progress}
                                            variant="solid"
                                            sx={{ height: 6 }}
                                        />
                                    </Box>
                                ))}
                            </Box>
                        </Card>
                    </motion.div>

                    {/* Quick Actions */}
                    <motion.div variants={itemVariants}>
                        <Card variant="outlined" sx={{ p: { xs: 1.5, sm: 2 } }}>
                            <Typography level="h3" sx={{ mb: 2, fontSize: { xs: "1.125rem", sm: "1.25rem" } }}>
                                Quick Actions
                            </Typography>
                            <Box sx={{ display: "flex", flexDirection: "column", gap: 1.5 }}>
                                <Button
                                    variant="solid"
                                    color="primary"
                                    onClick={() => navigate("/sports-management")}
                                    sx={{ justifyContent: "flex-start" }}
                                >
                                    ➕ Add New Sport
                                </Button>
                                <Button
                                    variant="outlined"
                                    color="primary"
                                    onClick={() => navigate("/sports-management")}
                                    sx={{ justifyContent: "flex-start" }}
                                >
                                    📊 Manage Sports
                                </Button>
                                <Button
                                    variant="outlined"
                                    color="neutral"
                                    sx={{ justifyContent: "flex-start" }}
                                >
                                    📈 View Reports
                                </Button>
                                <Button
                                    variant="outlined"
                                    color="neutral"
                                    sx={{ justifyContent: "flex-start" }}
                                >
                                    ⚙️ Settings
                                </Button>
                            </Box>
                        </Card>
                    </motion.div>
                </Box>

                {/* Recent Activities */}
                <motion.div variants={itemVariants} style={{ marginTop: "24px" }}>
                    <Card variant="outlined" sx={{ p: { xs: 1.5, sm: 2 } }}>
                        <Typography level="h3" sx={{ mb: 2, fontSize: { xs: "1.125rem", sm: "1.25rem" } }}>
                            Recent Activities
                        </Typography>
                        <Box sx={{ display: "flex", flexDirection: "column", gap: 1.5 }}>
                            {recentActivities.map((activity) => (
                                <motion.div key={activity.id} variants={itemVariants}>
                                    <Box
                                        sx={{
                                            display: "flex",
                                            alignItems: "flex-start",
                                            gap: 2,
                                            pb: 1.5,
                                            borderBottom: "1px solid",
                                            borderColor: "divider",
                                            "&:last-child": {
                                                borderBottom: "none",
                                            },
                                        }}
                                    >
                                        <Box
                                            sx={{
                                                width: 8,
                                                height: 8,
                                                borderRadius: "50%",
                                                backgroundColor: "primary.main",
                                                mt: 1,
                                                flexShrink: 0,
                                            }}
                                        />
                                        <Box sx={{ flex: 1 }}>
                                            <Typography level="body-sm" sx={{ fontWeight: "md" }}>
                                                {activity.title}
                                            </Typography>
                                            <Box sx={{ display: "flex", gap: 1, mt: 0.5 }}>
                                                <Typography level="body-xs" sx={{ color: "neutral.500" }}>
                                                    {activity.user}
                                                </Typography>
                                                <Typography level="body-xs" sx={{ color: "neutral.400" }}>
                                                    • {activity.time}
                                                </Typography>
                                            </Box>
                                        </Box>
                                    </Box>
                                </motion.div>
                            ))}
                        </Box>
                    </Card>
                </motion.div>
            </Box>
        </motion.div>
    );
}

export default Dashboard;
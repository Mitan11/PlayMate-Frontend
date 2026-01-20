import React, { useEffect, useState, useContext } from "react";
import { motion } from "framer-motion";
import Box from "@mui/joy/Box";
import Card from "@mui/joy/Card";
import Typography from "@mui/joy/Typography";
import Button from "@mui/joy/Button";
import LinearProgress from "@mui/joy/LinearProgress";
import { useNavigate } from "react-router";
import axios from "axios";
import { AppContext } from "../context/AppContextProvider";
import { toast } from "react-hot-toast";
import Preloader from "../components/Preloader";

function Dashboard() {
    const navigate = useNavigate();
    const { backendUrl, aToken } = useContext(AppContext);

    const [stats, setStats] = useState(null);
    const [sportMetrics, setSportMetrics] = useState([]);
    const [recentActivities, setRecentActivities] = useState([]);
    const [loading, setLoading] = useState(true);

    // Fetch all dashboard data
    useEffect(() => {
        fetchDashboardData();
    }, []);

    const fetchDashboardData = async () => {
        try {
            setLoading(true);

            const headers = {
                Authorization: `Bearer ${aToken}`,
            };

            const [
                statsRes,
                metricsRes,
                activitiesRes,
            ] = await Promise.all([
                axios.get(`${backendUrl}/admin/dashboard/stats`, { headers }),
                axios.get(`${backendUrl}/admin/dashboard/sport/metrics`, { headers }),
                axios.get(`${backendUrl}/admin/dashboard/recent/activities`, { headers }),
            ]);

            setStats(statsRes.data.data);
            setSportMetrics(metricsRes.data.data || []);
            setRecentActivities(activitiesRes.data.data || []);

        } catch (error) {
            console.log("Error fetching dashboard data:", error);
            // toast.error("Failed to load dashboard data");
        } finally {
            setLoading(false);
        }
    };

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
            style={{ width: "100%", overflowX: "hidden" }}
        >
            <Box sx={{ p: { xs: 1.5, sm: 2, md: 3 } }}>
                {/* Header */}
                <Box sx={{ mb: 3, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <Box >

                        <Typography level="h1" sx={{ mb: 0.5 }}>
                            Welcome Back, Admin!
                        </Typography>
                        <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                            Here's an overview of your sports management platform
                        </Typography>
                    </Box>
                    <Box sx={{ display: "flex", gap: 1 }}>
                        <Button onClick={() => navigate("/admin/analytics")}>
                            View Analytics
                        </Button>
                        <Button
                            variant="outlined"
                            color="neutral"
                            loading={loading}
                            onClick={fetchDashboardData}
                        >
                            Refresh
                        </Button>
                    </Box>
                </Box>

                {/* Stats Cards */}
                <Box
                    sx={{
                        display: "grid",
                        gridTemplateColumns: {
                            xs: "1fr",
                            sm: "repeat(2, 1fr)",
                            md: "repeat(4, 1fr)",
                        },
                        gap: 2,
                        mb: 3,
                    }}
                >
                    {stats ? (
                        [
                            { label: "Total Sports", value: stats?.totalSports || 0, icon: "⚽" },
                            { label: "Active Sessions", value: stats?.activeSessions || 0, icon: "🎮" },
                            { label: "Total Users", value: stats?.totalUsers || 0, icon: "👥" },
                            { label: "Revenue", value: `₹${stats?.totalRevenue || 0}`, icon: "💰" },
                            { label: "Total Venue", value: stats?.totalVenue || 0, icon: "🏟️" },
                            { label: "Total Posts", value: stats?.totalPosts || 0, icon: "📝" },
                        ].map((stat, index) => (
                            <motion.div key={index} variants={itemVariants}>
                                <Card variant="outlined" sx={{ p: 2 }}>
                                    <Typography level="body-xs" sx={{ color: "neutral.500" }}>
                                        {stat.label}
                                    </Typography>
                                    <Typography level="h3">
                                        {stat.icon} {stat.value}
                                    </Typography>
                                </Card>
                            </motion.div>
                        ))
                    ) : (
                        <Typography level="body-sm" sx={{ color: "neutral.500", gridColumn: "1 / -1" }}>
                            No statistics available
                        </Typography>
                    )}
                </Box>

                {/* Middle Grid */}
                <Box
                    sx={{
                        display: "grid",
                        gridTemplateColumns: { xs: "1fr", md: "2fr 1fr" },
                        gap: 3,
                    }}
                >
                    {/* Sport Metrics */}
                    <Card variant="outlined" sx={{ p: 2 }}>
                        <Typography level="h3" sx={{ mb: 2 }}>
                            Sports Popularity
                        </Typography>
                        {sportMetrics && sportMetrics.length > 0 ? (
                            <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                                {sportMetrics.map((sport, index) => (
                                    <Box key={index}>
                                        <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                                            <Typography level="body-sm">{sport.name}</Typography>
                                            <Typography level="body-xs" sx={{ color: "neutral.500" }}>
                                                {sport.users} users
                                            </Typography>
                                        </Box>
                                        <LinearProgress determinate value={sport.progress} />
                                    </Box>
                                ))}
                            </Box>
                        ) : (
                            <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                No sports data available
                            </Typography>
                        )}
                    </Card>

                    {/* Quick Actions */}
                    <Card variant="outlined" sx={{ p: 2 }}>
                        <Typography level="h3" sx={{ mb: 2 }}>
                            Quick Actions
                        </Typography>
                        <Box sx={{ display: "flex", flexDirection: "column", gap: 1.5 }}>
                            <Button onClick={() => navigate("/sports-management")}>
                                Add New Sport
                            </Button>
                            <Button variant="outlined" onClick={() => navigate("/sports-management")}>
                                Manage Sports
                            </Button>
                            <Button variant="outlined "
                                onClick={() => navigate("/admin/analytics")}
                            >View Reports</Button>
                        </Box>
                    </Card>
                </Box>

                {/* Recent Activities */}
                <Card variant="outlined" sx={{ mt: 3, p: 2 }}>
                    <Typography level="h3" sx={{ mb: 2 }}>
                        Recent Activities
                    </Typography>
                    {recentActivities && recentActivities.length > 0 ? (
                        <Box sx={{ display: "flex", flexDirection: "column", gap: 1.5 }}>
                            {recentActivities.map((activity, index) => (
                                <Box key={index}>
                                    <Typography level="body-sm">
                                        {activity.title}
                                    </Typography>
                                    <Typography level="body-xs" sx={{ color: "neutral.500" }}>
                                        {activity.user} • {activity.time}
                                    </Typography>
                                </Box>
                            ))}
                        </Box>
                    ) : (
                        <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                            No recent activities available
                        </Typography>
                    )}
                </Card>
            </Box>
        </motion.div>
    );
}

export default Dashboard;

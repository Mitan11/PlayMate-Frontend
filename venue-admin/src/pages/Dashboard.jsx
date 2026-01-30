import React, { useState, useEffect, useContext, useCallback, useMemo } from "react";
import { motion } from "framer-motion";
import Box from "@mui/joy/Box";
import Card from "@mui/joy/Card";
import Typography from "@mui/joy/Typography";
import Button from "@mui/joy/Button";
import LinearProgress from "@mui/joy/LinearProgress";
import Alert from "@mui/joy/Alert";
import { useNavigate } from "react-router";
import { AppContext } from '../context/AppContextProvider';
import axios from 'axios';
import toast from 'react-hot-toast';
import Preloader from "../components/Preloader";
import { FaInfoCircle, FaTimes } from "react-icons/fa";

function Dashboard() {
    const { venueOwner, backendUrl, token } = useContext(AppContext);
    const [loading, setLoading] = useState(true);
    const [showProfileAlert, setShowProfileAlert] = useState(true);
    const [stats, setStats] = useState({
        total_bookings: 0,
        total_revenue: "0.00",
        today_revenue: "0.00",
        total_sports: 0
    });

    const [recentBookings, setRecentBookings] = useState([]);

    const navigate = useNavigate();

    // Check if profile is incomplete
    const isProfileIncomplete = useMemo(() => {
        return !venueOwner?.venue_name || !venueOwner?.address || 
               venueOwner?.venue_name === "" || venueOwner?.address === "";
    }, [venueOwner]);

    // Fetch dashboard stats
    const fetchDashboardStats = useCallback(async () => {
        setLoading(true)
        if (!venueOwner?.venue_id || !token) {
            setLoading(false);
            return;
        }

        try {
            const response = await axios.get(
                `${backendUrl}/venue/dashboard/stats/${venueOwner.venue_id}`,
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status) {
                setStats(response.data.data);
            } else {
                toast.error('Failed to fetch dashboard stats');
            }

            // Fetch recent bookings
            try {
                const bookingsResponse = await axios.get(
                    `${backendUrl}/venue/analytics/recent-bookings/${venueOwner.venue_id}`,
                    {
                        headers: {
                            Authorization: `Bearer ${token}`
                        }
                    }
                );
                if (bookingsResponse.data.status) {
                    setRecentBookings(bookingsResponse.data.data || []);
                }
            } catch (bookingError) {
                console.log('Recent bookings not available:', bookingError);
            }
        } catch (error) {
            console.error('Dashboard stats error:', error);
            toast.error('Error loading dashboard data');
            if (error.response?.status === 401) {
                navigate('/login');
            }
        } finally {
            setLoading(false);
        }
    }, [venueOwner?.venue_id, token, backendUrl, navigate]);

    useEffect(() => {
        document.title = "PlayMate | Dashboard";
        fetchDashboardStats();
    }, [fetchDashboardStats]);

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
                {/* Profile Completion Alert */}
                {isProfileIncomplete && showProfileAlert && (
                    <motion.div
                        initial={{ opacity: 0, y: -20 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -20 }}
                        transition={{ duration: 0.3 }}
                    >
                        <Alert
                            color="warning"
                            variant="soft"
                            sx={{
                                mb: 3,
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'space-between',
                                '& .MuiAlert-startDecorator': {
                                    mr: 1.5
                                }
                            }}
                            startDecorator={<FaInfoCircle />}
                            endDecorator={
                                <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                                    <Button
                                        size="sm"
                                        variant="solid"
                                        color="warning"
                                        onClick={() => navigate("/profile")}
                                    >
                                        Complete Profile
                                    </Button>
                                    <Button
                                        size="sm"
                                        variant="plain"
                                        color="neutral"
                                        onClick={() => setShowProfileAlert(false)}
                                        sx={{ minWidth: 'auto', p: 0.5 }}
                                    >
                                        <FaTimes />
                                    </Button>
                                </Box>
                            }
                        >
                            <Box>
                                <Typography level="title-md" sx={{ mb: 0.5 }}>
                                    Complete Your Profile
                                </Typography>
                                <Typography level="body-sm">
                                    Please add your venue name and address to get started with bookings.
                                </Typography>
                            </Box>
                        </Alert>
                    </motion.div>
                )}

                {/* Header Section */}
                <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <Box>
                        <Typography level="h1" sx={{ mb: 0.5, fontSize: { xs: "1.5rem", sm: "1.875rem", md: "2.25rem" } }}>
                            Welcome Back, {venueOwner?.first_name || 'Owner'}!
                        </Typography>
                        <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                            Here's an overview of your venue performance
                        </Typography>
                    </Box>
                    <Box sx={{ display: 'flex', gap: 2 }}>
                        <Button
                            variant="solid"
                            color="primary"
                            onClick={() => navigate("/analytics")}
                            sx={{ px: 3 }}
                        >
                            View Analytics
                        </Button>
                        <Button
                            variant="outlined"
                            size="sm"
                            loading={loading}
                            onClick={fetchDashboardStats}
                            sx={{
                                minWidth: 'auto',
                                px: 2
                            }}
                        >
                            {loading ? 'Refreshing...' : 'Refresh'}
                        </Button>
                    </Box>
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
                                label: "Total Bookings",
                                value: stats.total_bookings,
                                icon: "📅",
                                color: "#3b82f6",
                            },
                            {
                                label: "Total Revenue",
                                value: `₹${stats.total_revenue}`,
                                icon: "💰",
                                color: "#10b981",
                            },
                            {
                                label: "Today's Revenue",
                                value: `₹${stats.today_revenue}`,
                                icon: "📊",
                                color: "#8b5cf6",
                            },
                            {
                                label: "Total Sports",
                                value: stats.total_sports,
                                icon: "⚽",
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
                                        value={
                                            index === 0 ? Math.min((stats.total_bookings / 50) * 100, 100) : // Bookings progress
                                                index === 1 ? Math.min((parseFloat(stats.total_revenue) / 1000) * 100, 100) : // Revenue progress
                                                    index === 2 ? Math.min((parseFloat(stats.today_revenue) / 100) * 100, 100) : // Today's revenue progress
                                                        Math.min((stats.total_sports / 10) * 100, 100) // Sports progress
                                        }
                                        variant="solid"
                                        color="primary"
                                        sx={{
                                            height: 4,
                                            backgroundColor: 'rgba(59, 130, 246, 0.1)'
                                        }}
                                    />
                                </Card>
                            </motion.div>
                        ))}
                    </Box>
                </motion.div>

                {/* Recent Bookings Section */}
                <motion.div variants={itemVariants}>
                    <Card variant="outlined" sx={{ p: { xs: 2, sm: 3 }, mb: 3 }}>
                        <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
                            <Typography level="h3" sx={{ fontSize: { xs: "1.125rem", sm: "1.25rem" }, display: 'flex', alignItems: 'center', gap: 1 }}>
                                📋 Recent Bookings
                            </Typography>
                            <Button
                                variant="outlined"
                                size="sm"
                                onClick={() => navigate("/bookings")}
                            >
                                View All
                            </Button>
                        </Box>

                        {recentBookings.length > 0 ? (
                            <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                                {recentBookings.slice(0, 5).map((booking, index) => (
                                    <motion.div key={booking.booking_id || index} variants={itemVariants}>
                                        <Box
                                            sx={{
                                                display: "flex",
                                                alignItems: "center",
                                                justifyContent: "space-between",
                                                p: 2,
                                                borderRadius: "8px",
                                                border: "1px solid",
                                                borderColor: "neutral.200",
                                                backgroundColor: "background.surface",
                                                transition: "all 0.2s",
                                                "&:hover": {
                                                    borderColor: "primary.300",
                                                    backgroundColor: "primary.50",
                                                    transform: "translateY(-1px)",
                                                    boxShadow: "0 2px 8px rgba(0,0,0,0.1)",
                                                },
                                            }}
                                        >
                                            <Box sx={{ display: "flex", alignItems: "center", gap: 2, flex: 1 }}>
                                                <Box
                                                    sx={{
                                                        width: 40,
                                                        height: 40,
                                                        borderRadius: "50%",
                                                        backgroundColor: "primary.100",
                                                        display: "flex",
                                                        alignItems: "center",
                                                        justifyContent: "center",
                                                        flexShrink: 0,
                                                    }}
                                                >
                                                    <Typography sx={{ fontSize: "1.2rem" }}>🏆</Typography>
                                                </Box>
                                                <Box sx={{ flex: 1, minWidth: 0 }}>
                                                    <Typography level="body-sm" sx={{ fontWeight: 600, mb: 0.25 }}>
                                                        {`${booking.first_name} ${booking.last_name}`}
                                                    </Typography>
                                                    <Typography level="body-xs" sx={{ color: "neutral.500", mb: 0.25 }}>
                                                        {`${new Date(booking.start_datetime).toLocaleTimeString()} - ${new Date(booking.end_datetime).toLocaleTimeString()}`}
                                                    </Typography>
                                                    <Typography level="body-xs" sx={{ color: "neutral.400" }}>
                                                        {new Date(booking.start_datetime).toLocaleDateString()}
                                                    </Typography>
                                                </Box>
                                            </Box>
                                            <Box sx={{ textAlign: "right" }}>
                                                <Typography
                                                    level="body-sm"
                                                    sx={{
                                                        fontWeight: 600,
                                                        color: 'success.600',
                                                        fontSize: '0.875rem'
                                                    }}
                                                >
                                                    ₹{booking.total_price}
                                                </Typography>
                                                <Typography level="body-xs" sx={{ color: "neutral.400" }}>
                                                    #{booking.booking_id}
                                                </Typography>
                                            </Box>
                                        </Box>
                                    </motion.div>
                                ))}
                            </Box>
                        ) : (
                            <Box sx={{ textAlign: "center", py: 4 }}>
                                <Typography sx={{ fontSize: "3rem", mb: 1 }}>📋</Typography>
                                <Typography level="h4" sx={{ mb: 1, color: "neutral.500" }}>
                                    No Recent Bookings
                                </Typography>
                                <Typography level="body-sm" sx={{ color: "neutral.400" }}>
                                    When customers book your venue, they'll appear here
                                </Typography>
                            </Box>
                        )}
                    </Card>
                </motion.div>




            </Box>
        </motion.div>
    );
}

export default Dashboard;
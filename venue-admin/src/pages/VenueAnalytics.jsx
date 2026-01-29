import React, { useEffect, useState, useContext } from "react";
import axios from "axios";
import { AppContext } from "../context/AppContextProvider";
import { toast } from "react-hot-toast";
import { motion } from "framer-motion";

import {
    LineChart, Line, BarChart, Bar, PieChart, Pie, Cell,
    XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from "recharts";

import Box from "@mui/joy/Box";
import Card from "@mui/joy/Card";
import Typography from "@mui/joy/Typography";
import Button from "@mui/joy/Button";
import Skeleton from "@mui/joy/Skeleton";
import Grid from "@mui/joy/Grid";
import Divider from "@mui/joy/Divider";
import Chip from "@mui/joy/Chip";
import Table from "@mui/joy/Table";
import {
    FaChartLine,
    FaMoneyBillWave,
    FaClock,
    FaUsers,
    FaTrophy,
    FaGamepad,
    FaCalendarCheck,
    FaArrowLeft
} from "react-icons/fa";
import { useNavigate } from "react-router";
import Preloader from "../components/Preloader";

function VenueAnalytics() {
    const { backendUrl, token, venueOwner } = useContext(AppContext);
    const navigate = useNavigate();

    // Analytics state
    const [dailyBookingTrend, setDailyBookingTrend] = useState([]);
    const [monthlyRevenueTrend, setMonthlyRevenueTrend] = useState([]);
    const [revenueBySport, setRevenueBySport] = useState([]);
    const [revenueBySlot, setRevenueBySlot] = useState([]);
    const [mostBookedSlots, setMostBookedSlots] = useState([]);
    const [peakBookingHours, setPeakBookingHours] = useState([]);
    const [slotUsageFrequency, setSlotUsageFrequency] = useState([]);
    const [unusedSlots, setUnusedSlots] = useState([]);
    const [uniqueCustomers, setUniqueCustomers] = useState(0);
    const [repeatCustomers, setRepeatCustomers] = useState(0);
    const [topCustomers, setTopCustomers] = useState([]);
    const [totalGames, setTotalGames] = useState(0);
    const [gamesBySport, setGamesBySport] = useState([]);
    const [recentBookings, setRecentBookings] = useState([]);

    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (venueOwner?.venue_id) {
            fetchAllAnalytics();
        }
    }, [venueOwner?.venue_id]);

    const fetchAllAnalytics = async () => {
        if (!venueOwner?.venue_id || !token) {
            setLoading(false);
            return;
        }

        try {
            setLoading(true);
            const headers = { Authorization: `Bearer ${token}` };
            const venueId = venueOwner.venue_id;

            // Fetch all analytics data in parallel
            const [
                dailyTrendRes,
                monthlyRevenueRes,
                revenueBySportRes,
                revenueBySlotRes,
                mostBookedSlotsRes,
                peakHoursRes,
                slotUsageRes,
                unusedSlotsRes,
                uniqueCustomersRes,
                repeatCustomersRes,
                topCustomersRes,
                totalGamesRes,
                gamesBySportRes,
                recentBookingsRes,
            ] = await Promise.all([
                axios.get(`${backendUrl}/venue/analytics/daily-booking-trend/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/monthly-revenue-trend/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/revenue-by-sport/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/revenue-by-slot/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/most-booked-slots/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/peak-booking-hours/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/slot-usage-frequency/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/unused-slots/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/unique-customers/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/repeat-customers/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/top-customers/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/total-games-hosted/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/games-by-sport/${venueId}`, { headers }),
                axios.get(`${backendUrl}/venue/analytics/recent-bookings/${venueId}?limit=10`, { headers }),
            ]);

            // Format data
            setDailyBookingTrend(formatDailyBookingData(dailyTrendRes.data.data || []));
            setMonthlyRevenueTrend(formatMonthlyRevenueData(monthlyRevenueRes.data.data || []));
            setRevenueBySport(formatRevenueBySportData(revenueBySportRes.data.data || []));
            setRevenueBySlot(formatSlotRevenueData(revenueBySlotRes.data.data || []));
            setMostBookedSlots(formatSlotBookingData(mostBookedSlotsRes.data.data || []));
            setPeakBookingHours(peakHoursRes.data.data || []);
            setSlotUsageFrequency(formatSlotUsageData(slotUsageRes.data.data || []));
            setUnusedSlots(unusedSlotsRes.data.data || []);
            setUniqueCustomers(uniqueCustomersRes.data.data?.unique_customers || 0);
            setRepeatCustomers(repeatCustomersRes.data.data?.repeat_customers || 0);
            setTopCustomers(topCustomersRes.data.data || []);
            setTotalGames(totalGamesRes.data.data?.total_games || 0);
            setGamesBySport(gamesBySportRes.data.data || []);
            setRecentBookings(recentBookingsRes.data.data || []);

        } catch (error) {
            console.error("Error fetching analytics data:", error);
            toast.error("Failed to load analytics data");
            if (error.response?.status === 401) {
                navigate('/login');
            }
        } finally {
            setLoading(false);
        }
    };

    // Format functions
    const formatDailyBookingData = (data) =>
        data.map(item => ({
            date: new Date(item.booking_date).toLocaleDateString(),
            bookings: item.bookings
        }));

    const formatMonthlyRevenueData = (data) =>
        data.map(item => ({
            month: item.month,
            revenue: parseFloat(item.revenue) || 0
        }));

    const formatRevenueBySportData = (data) =>
        data.map(item => ({
            sport_name: item.sport_name,
            revenue: parseFloat(item.revenue) || 0
        }));

    const formatSlotRevenueData = (data) =>
        data.map(item => ({
            slot: `${item.start_time} - ${item.end_time}`,
            revenue: parseFloat(item.revenue) || 0
        }));

    const formatSlotBookingData = (data) =>
        data.map(item => ({
            slot: `${item.start_time} - ${item.end_time}`,
            bookings: item.total_bookings
        }));

    const formatSlotUsageData = (data) =>
        data.map(item => ({
            slot: `${item.start_time} - ${item.end_time}`,
            usage: item.times_booked
        }));

    const COLORS = ['#8884d8', '#82ca9d', '#ffc658', '#ff7300', '#00ff00'];

    const containerVariants = {
        hidden: { opacity: 0, y: 20 },
        visible: {
            opacity: 1,
            y: 0,
            transition: { duration: 0.6, staggerChildren: 0.1 }
        }
    };

    const itemVariants = {
        hidden: { opacity: 0, y: 20 },
        visible: { opacity: 1, y: 0 }
    };

    if (loading) {
        return <Preloader />;
    }
    console.log(gamesBySport)
    return (
        <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
        >
            <Box sx={{ p: { xs: 2, md: 3 } }}>
                {/* Header */}
                <Box sx={{ mb: 4, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <Box>
                        <Typography level="h1" sx={{ mb: 0.5, display: 'flex', alignItems: 'center', gap: 2 }}>
                            Venue Analytics
                        </Typography>
                        <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                            Comprehensive insights into your venue performance
                        </Typography>
                    </Box>
                    <Button
                        variant="outlined"
                        startDecorator={<FaArrowLeft />}
                        onClick={() => navigate("/dashboard")}
                    >
                        Back to Dashboard
                    </Button>
                </Box>

                {/* Key Metrics Cards */}
                <motion.div variants={itemVariants}>
                    <Grid container spacing={3} sx={{ mb: 4 }}>
                        <Grid xs={12} sm={6} md={3}>
                            <Card variant="outlined" sx={{ p: 2, textAlign: 'center' }}>
                                <FaUsers size={32} color="#3b82f6" style={{ marginBottom: '8px' }} />
                                <Typography level="h2" sx={{ color: 'primary.500' }}>
                                    {uniqueCustomers}
                                </Typography>
                                <Typography level="body-sm">Unique Customers</Typography>
                            </Card>
                        </Grid>
                        <Grid xs={12} sm={6} md={3}>
                            <Card variant="outlined" sx={{ p: 2, textAlign: 'center' }}>
                                <FaTrophy size={32} color="#10b981" style={{ marginBottom: '8px' }} />
                                <Typography level="h2" sx={{ color: 'success.500' }}>
                                    {repeatCustomers}
                                </Typography>
                                <Typography level="body-sm">Repeat Customers</Typography>
                            </Card>
                        </Grid>
                        <Grid xs={12} sm={6} md={3}>
                            <Card variant="outlined" sx={{ p: 2, textAlign: 'center' }}>
                                <FaGamepad size={32} color="#f59e0b" style={{ marginBottom: '8px' }} />
                                <Typography level="h2" sx={{ color: 'warning.500' }}>
                                    {totalGames}
                                </Typography>
                                <Typography level="body-sm">Total Games Hosted</Typography>
                            </Card>
                        </Grid>
                        <Grid xs={12} sm={6} md={3}>
                            <Card variant="outlined" sx={{ p: 2, textAlign: 'center' }}>
                                <FaCalendarCheck size={32} color="#8b5cf6" style={{ marginBottom: '8px' }} />
                                <Typography level="h2" sx={{ color: 'primary.500' }}>
                                    {unusedSlots.length}
                                </Typography>
                                <Typography level="body-sm">Unused Slots</Typography>
                            </Card>
                        </Grid>
                    </Grid>
                </motion.div>

                {/* Charts Grid */}
                <Grid container spacing={3}>
                    {/* Daily Booking Trend */}
                    <Grid xs={12} lg={6}>
                        <motion.div variants={itemVariants}>
                            <Card variant="outlined" sx={{ p: 3 }}>
                                <Typography level="h4" sx={{
                                    mb: 2,
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: 1,
                                    fontSize: { xs: '1rem', sm: '1.125rem' },
                                    flexWrap: 'wrap',
                                    wordBreak: 'break-word'
                                }}>
                                    <FaChartLine color="#3b82f6" />
                                    Daily Booking Trend
                                </Typography>
                                <ResponsiveContainer width="100%" height={300}>
                                    <LineChart data={dailyBookingTrend}>
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis dataKey="date" />
                                        <YAxis />
                                        <Tooltip />
                                        <Line type="monotone" dataKey="bookings" stroke="#3b82f6" strokeWidth={2} />
                                    </LineChart>
                                </ResponsiveContainer>
                            </Card>
                        </motion.div>
                    </Grid>

                    {/* Monthly Revenue Trend */}
                    <Grid xs={12} lg={6}>
                        <motion.div variants={itemVariants}>
                            <Card variant="outlined" sx={{ p: 3 }}>
                                <Typography level="h4" sx={{
                                    mb: 2,
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: 1,
                                    fontSize: { xs: '1rem', sm: '1.125rem' },
                                    flexWrap: 'wrap',
                                    wordBreak: 'break-word'
                                }}>
                                    <FaMoneyBillWave color="#10b981" />
                                    Monthly Revenue Trend
                                </Typography>
                                <ResponsiveContainer width="100%" height={300}>
                                    <BarChart data={monthlyRevenueTrend}>
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis dataKey="month" />
                                        <YAxis />
                                        <Tooltip formatter={(value) => [`₹${value}`, 'Revenue']} />
                                        <Bar dataKey="revenue" fill="#10b981" />
                                    </BarChart>
                                </ResponsiveContainer>
                            </Card>
                        </motion.div>
                    </Grid>

                    {/* Revenue by Sport */}
                    <Grid xs={12} lg={6}>
                        <motion.div variants={itemVariants}>
                            <Card variant="outlined" sx={{ p: 3 }}>
                                <Typography level="h4" sx={{
                                    mb: 2,
                                    fontSize: { xs: '1rem', sm: '1.125rem' },
                                    wordBreak: 'break-word'
                                }}>Revenue by Sport</Typography>
                                <ResponsiveContainer width="100%" height={300}>
                                    <PieChart>
                                        <Pie
                                            data={revenueBySport}
                                            cx="50%"
                                            cy="50%"
                                            labelLine={false}
                                            label={({ sport_name, revenue }) => `${sport_name}: ₹${revenue}`}
                                            outerRadius={80}
                                            fill="#8884d8"
                                            dataKey="revenue"
                                        >
                                            {revenueBySport.map((entry, index) => (
                                                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                            ))}
                                        </Pie>
                                        <Tooltip formatter={(value) => [`₹${value}`, 'Revenue']} />
                                    </PieChart>
                                </ResponsiveContainer>
                            </Card>
                        </motion.div>
                    </Grid>

                    {/* Peak Booking Hours */}
                    <Grid xs={12} lg={6}>
                        <motion.div variants={itemVariants}>
                            <Card variant="outlined" sx={{ p: 3 }}>
                                <Typography level="h4" sx={{
                                    mb: 2,
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: 1,
                                    fontSize: { xs: '1rem', sm: '1.125rem' },
                                    flexWrap: 'wrap',
                                    wordBreak: 'break-word'
                                }}>
                                    <FaClock color="#f59e0b" />
                                    Peak Booking Hours
                                </Typography>
                                <ResponsiveContainer width="100%" height={300}>
                                    <BarChart data={peakBookingHours}>
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis dataKey="hour" />
                                        <YAxis />
                                        <Tooltip />
                                        <Bar dataKey="bookings" fill="#f59e0b" />
                                    </BarChart>
                                </ResponsiveContainer>
                            </Card>
                        </motion.div>
                    </Grid>

                    {/* Top Customers Table */}
                    <Grid xs={12} lg={6}>
                        <motion.div variants={itemVariants}>
                            <Card variant="outlined" sx={{ p: 3 }}>
                                <Typography level="h4" sx={{ mb: 2 }}>Top Customers</Typography>
                                <Box sx={{ maxHeight: 300, overflowY: 'auto' }}>
                                    <Table>
                                        <thead>
                                            <tr>
                                                <th>Customer</th>
                                                <th>Bookings</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {topCustomers.map((customer, index) => (
                                                <tr key={index}>
                                                    <td>{`${customer.first_name} ${customer.last_name}`}</td>
                                                    <td>
                                                        <Chip variant="soft" color="primary">
                                                            {customer.bookings_count}
                                                        </Chip>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </Table>
                                </Box>
                            </Card>
                        </motion.div>
                    </Grid>

                    {/* Recent Bookings */}
                    <Grid xs={12} lg={6}>
                        <motion.div variants={itemVariants}>
                            <Card variant="outlined" sx={{ p: 3 }}>
                                <Typography level="h4" sx={{ mb: 2 }}>Recent Bookings</Typography>
                                <Box sx={{ maxHeight: 300, overflowY: 'auto' }}>
                                    <Table>
                                        <thead>
                                            <tr>
                                                <th>Customer</th>
                                                <th>Time Slot</th>
                                                <th>Amount</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {recentBookings.map((booking, index) => (
                                                <tr key={index}>
                                                    <td>{`${booking.first_name} ${booking.last_name}`}</td>
                                                    <td>{`${new Date(booking.start_datetime).toLocaleTimeString()} - ${new Date(booking.end_datetime).toLocaleTimeString()}`}</td>
                                                    <td>
                                                        <Chip variant="soft" color="success">
                                                            ₹{booking.total_price}
                                                        </Chip>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </Table>
                                </Box>
                            </Card>
                        </motion.div>
                    </Grid>

                    {/* Unused Slots */}
                    <Grid xs={12}>
                        <motion.div variants={itemVariants}>
                            <Card variant="outlined" sx={{ p: 3 }}>
                                <Typography level="h4" sx={{ mb: 2 }}>Unused Time Slots</Typography>
                                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                                    {unusedSlots.map((slot, index) => (
                                        <Chip key={index} variant="outlined" color="warning">
                                            {`${slot.start_time} - ${slot.end_time}`}
                                        </Chip>
                                    ))}
                                    {unusedSlots.length === 0 && (
                                        <Typography level="body-sm" sx={{ color: 'success.500' }}>
                                            🎉 All time slots are being utilized!
                                        </Typography>
                                    )}
                                </Box>
                            </Card>
                        </motion.div>
                    </Grid>

                    {/* Revenue by Slot */}
                    <Grid xs={12} lg={6}>
                        <motion.div variants={itemVariants}>
                            <Card variant="outlined" sx={{ p: 3 }}>
                                <Typography level="h4" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <FaMoneyBillWave color="#10b981" />
                                    Revenue by Time Slot
                                </Typography>
                                <ResponsiveContainer width="100%" height={300}>
                                    <BarChart data={revenueBySlot} margin={{ bottom: 60 }}>
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis
                                            dataKey="slot"
                                            angle={-45}
                                            textAnchor="end"
                                            height={50}
                                            interval={0}
                                            fontSize={12}
                                        />
                                        <YAxis />
                                        <Tooltip formatter={(value) => [`₹${value}`, 'Revenue']} />
                                        <Bar dataKey="revenue" fill="#10b981" />
                                    </BarChart>
                                </ResponsiveContainer>
                            </Card>
                        </motion.div>
                    </Grid>

                    {/* Most Booked Slots */}
                    <Grid xs={12} lg={6}>
                        <motion.div variants={itemVariants}>
                            <Card variant="outlined" sx={{ p: 3 }}>
                                <Typography level="h4" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <FaTrophy color="#f59e0b" />
                                    Most Booked Slots
                                </Typography>
                                <ResponsiveContainer width="100%" height={300}>
                                    <BarChart data={mostBookedSlots} margin={{ bottom: 60 }}>
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis
                                            dataKey="slot"
                                            angle={-45}
                                            textAnchor="end"
                                            height={50}
                                            interval={0}
                                            fontSize={12}
                                        />
                                        <YAxis />
                                        <Tooltip />
                                        <Bar dataKey="bookings" fill="#f59e0b" />
                                    </BarChart>
                                </ResponsiveContainer>
                            </Card>
                        </motion.div>
                    </Grid>

                    {/* Slot Usage Frequency */}
                    <Grid xs={12} lg={6}>
                        <motion.div variants={itemVariants}>
                            <Card variant="outlined" sx={{ p: 3 }}>
                                <Typography level="h4" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <FaClock color="#8b5cf6" />
                                    Slot Usage Frequency
                                </Typography>
                                <ResponsiveContainer width="100%" height={300}>
                                    <LineChart data={slotUsageFrequency} margin={{ bottom: 60 }}>
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis
                                            dataKey="slot"
                                            angle={-45}
                                            textAnchor="end"
                                            height={50}
                                            interval={0}
                                            fontSize={12}
                                        />
                                        <YAxis />
                                        <Tooltip />
                                        <Line type="monotone" dataKey="usage" stroke="#8b5cf6" strokeWidth={2} />
                                    </LineChart>
                                </ResponsiveContainer>
                            </Card>
                        </motion.div>
                    </Grid>

                    {/* Games by Sport */}
                    <Grid xs={12} lg={6}>
                        <motion.div variants={itemVariants}>
                            <Card variant="outlined" sx={{ p: 3 }}>
                                <Typography level="h4" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <FaGamepad color="#ef4444" />
                                    Games by Sport
                                </Typography>
                                <ResponsiveContainer width="100%" height={300}>
                                    <PieChart>
                                        <Pie
                                            data={gamesBySport}
                                            cx="50%"
                                            cy="50%"
                                            labelLine={false}
                                            label={({ sport_name, games_count }) => `${sport_name}: ${games_count}`}
                                            outerRadius={80}
                                            fill="#8884d8"
                                            dataKey="games_count"
                                        >
                                            {gamesBySport.map((entry, index) => (
                                                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                            ))}
                                        </Pie>
                                        <Tooltip formatter={(value) => [`${value}`, 'Games']} />
                                    </PieChart>
                                </ResponsiveContainer>
                            </Card>
                        </motion.div>
                    </Grid>
                </Grid>
            </Box>
        </motion.div>
    );
}

export default VenueAnalytics;
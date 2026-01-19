import React, { useEffect, useState, useContext, useMemo } from "react";
import axios from "axios";
import { AppContext } from "../context/AppContextProvider";
import { toast } from "react-hot-toast";

import {
    LineChart, Line, BarChart, Bar, PieChart, Pie, Cell,
    XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from "recharts";

import Box from "@mui/joy/Box";
import Card from "@mui/joy/Card";
import Typography from "@mui/joy/Typography";
import Select from "@mui/joy/Select";
import Option from "@mui/joy/Option";
import Skeleton from "@mui/joy/Skeleton";
import Preloader from "../components/Preloader";
import Grid from "@mui/joy/Grid";
import Divider from "@mui/joy/Divider";

function AdminAnalytics() {
    const { backendUrl, aToken } = useContext(AppContext);

    // Existing state
    const [bookingData, setBookingData] = useState([]);
    const [revenueData, setRevenueData] = useState([]);
    const [userData, setUserData] = useState([]);

    // New analytics state
    const [userGrowthData, setUserGrowthData] = useState([]);
    const [venueGrowthData, setVenueGrowthData] = useState([]);
    const [bookingTrendData, setBookingTrendData] = useState([]);
    const [monthlyRevenueData, setMonthlyRevenueData] = useState([]);
    const [revenueByVenueData, setRevenueByVenueData] = useState([]);
    const [revenueBySportData, setRevenueBySportData] = useState([]);
    const [mostPlayedSportsData, setMostPlayedSportsData] = useState([]);
    const [mostBookedVenuesData, setMostBookedVenuesData] = useState([]);
    const [peakBookingHoursData, setPeakBookingHoursData] = useState([]);
    const [topUsersByBookingsData, setTopUsersByBookingsData] = useState([]);
    const [mostLikedPostsData, setMostLikedPostsData] = useState([]);
    const [topContentCreatorsData, setTopContentCreatorsData] = useState([]);

    const [range, setRange] = useState("daily");
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchAllAnalytics();
    }, []);

    const fetchAllAnalytics = async () => {
        try {
            setLoading(true);
            const headers = { Authorization: `Bearer ${aToken}` };

            console.log('Fetching analytics from:', backendUrl);
            console.log('Using token:', aToken ? 'Token present' : 'No token');

            // Fetch all analytics data in parallel
            const [
                userGrowthRes,
                venueGrowthRes,
                bookingTrendRes,
                monthlyRevenueRes,
                revenueByVenueRes,
                revenueBySportRes,
                mostPlayedSportsRes,
                mostBookedVenuesRes,
                peakBookingHoursRes,
                topUsersByBookingsRes,
                mostLikedPostsRes,
                topContentCreatorsRes,
                // Legacy endpoints for backward compatibility
                bookingRes,
                revenueRes,
                userRes,
            ] = await Promise.all([
                axios.get(`${backendUrl}/admin/analytics/user-growth`, { headers }),
                axios.get(`${backendUrl}/admin/analytics/venue-growth`, { headers }),
                axios.get(`${backendUrl}/admin/analytics/booking-trend`, { headers }),
                axios.get(`${backendUrl}/admin/analytics/monthly-revenue`, { headers }),
                axios.get(`${backendUrl}/admin/analytics/revenue-by-venue`, { headers }),
                axios.get(`${backendUrl}/admin/analytics/revenue-by-sport`, { headers }),
                axios.get(`${backendUrl}/admin/analytics/most-played-sports`, { headers }),
                axios.get(`${backendUrl}/admin/analytics/most-booked-venues`, { headers }),
                axios.get(`${backendUrl}/admin/analytics/peak-booking-hours`, { headers }),
                axios.get(`${backendUrl}/admin/analytics/top-users-by-bookings`, { headers }),
                axios.get(`${backendUrl}/admin/analytics/most-liked-posts`, { headers }),
                axios.get(`${backendUrl}/admin/analytics/top-content-creators`, { headers }),
                // Legacy endpoints
                axios.get(`${backendUrl}/admin/dashboard/booking/report`, { headers }).catch(() => ({ data: { data: [] } })),
                axios.get(`${backendUrl}/admin/dashboard/revenue/report`, { headers }).catch(() => ({ data: { data: [] } })),
                axios.get(`${backendUrl}/admin/dashboard/user/report`, { headers }).catch(() => ({ data: { data: [] } })),
            ]);

            console.log('Raw API responses:', {
                userGrowth: userGrowthRes.data,
                venueGrowth: venueGrowthRes.data,
                bookingTrend: bookingTrendRes.data,
                monthlyRevenue: monthlyRevenueRes.data,
                revenueByVenue: revenueByVenueRes.data,
                revenueBySport: revenueBySportRes.data
            });

            // Set new analytics data
            const formattedUserGrowth = formatMonthlyData(userGrowthRes.data.data || [], "users_registered");
            const formattedVenueGrowth = formatMonthlyData(venueGrowthRes.data.data || [], "venues_added");
            const formattedBookingTrend = formatDailyData(bookingTrendRes.data.data || [], "total_bookings");
            const formattedMonthlyRevenue = formatMonthlyData(monthlyRevenueRes.data.data || [], "revenue");

            console.log('Formatted data:', {
                userGrowth: formattedUserGrowth,
                venueGrowth: formattedVenueGrowth,
                bookingTrend: formattedBookingTrend,
                monthlyRevenue: formattedMonthlyRevenue
            });

            setUserGrowthData(formattedUserGrowth);
            setVenueGrowthData(formattedVenueGrowth);
            setBookingTrendData(formattedBookingTrend);
            setMonthlyRevenueData(formattedMonthlyRevenue);

            // Process revenue data (convert string values to numbers)
            const processRevenueData = (data) => data.map(item => ({
                ...item,
                revenue: parseFloat(item.revenue) || 0
            }));

            console.log('Revenue by sport raw:', revenueBySportRes.data.data);
            const processedRevenueBySport = processRevenueData(revenueBySportRes.data.data || []);
            console.log('Revenue by sport processed:', processedRevenueBySport);

            setRevenueByVenueData(processRevenueData(revenueByVenueRes.data.data || []));
            setRevenueBySportData(processedRevenueBySport);
            setMostPlayedSportsData(mostPlayedSportsRes.data.data || []);
            setMostBookedVenuesData(mostBookedVenuesRes.data.data || []);
            setPeakBookingHoursData(formatHourlyData(peakBookingHoursRes.data.data || []));
            setTopUsersByBookingsData(topUsersByBookingsRes.data.data || []);
            setMostLikedPostsData(mostLikedPostsRes.data.data || []);
            setTopContentCreatorsData(topContentCreatorsRes.data.data || []);

            // Legacy data for backward compatibility
            setBookingData(formatData(bookingRes.data.data));
            setRevenueData(formatData(revenueRes.data.data, "revenue"));
            setUserData(formatData(userRes.data.data, "users"));
        } catch (error) {
            console.log("Error fetching analytics data:", error);
            // toast.error("Failed to load analytics");
        } finally {
            setLoading(false);
        }
    };
    console.log(revenueBySportData)
    // Format API data → chart friendly
    const formatData = (data, key = "bookings") =>
        data.map(item => ({
            date: new Date(item.date).toLocaleDateString(),
            [key]: item[key] ?? item.users ?? item.bookings
        }));

    // Format monthly data (YYYY-MM format)
    const formatMonthlyData = (data, valueKey) =>
        data.map(item => ({
            month: item.month,
            value: item[valueKey],
            [valueKey]: item[valueKey]
        }));

    // Format daily data (YYYY-MM-DD format)
    const formatDailyData = (data, valueKey) =>
        data.map(item => ({
            date: new Date(item.date).toLocaleDateString(),
            value: item[valueKey],
            [valueKey]: item[valueKey]
        }));

    // Format hourly data (0-23 hours)
    const formatHourlyData = (data) =>
        data.map(item => ({
            hour: `${item.hour}:00`,
            bookings: item.bookings,
            value: item.bookings
        }));

    // Color palette for charts
    const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#84cc16', '#f97316'];

    // Trend filter (daily / monthly)
    const filterTrend = (data) => {
        if (range === "daily") return data;

        const map = {};
        data.forEach(d => {
            const month = d.date.slice(3); // MM/YYYY
            map[month] = (map[month] || 0) + Object.values(d)[1];
        });

        return Object.keys(map).map(k => ({
            date: k,
            value: map[k]
        }));
    };

    if (loading) {
        return (
            <Preloader />
        );
    }
    console.log(mostBookedVenuesData);
    console.log(mostPlayedSportsData);
    return (
        <Box sx={{ p: 3, maxWidth: '100%', overflow: 'hidden' }}>
            <Box sx={{ mb: 3, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <Typography level="h2">Comprehensive Analytics Dashboard</Typography>
                <Select value={range} onChange={(_, v) => setRange(v)}>
                    <Option value="daily">Daily View</Option>
                    <Option value="monthly">Monthly View</Option>
                </Select>
            </Box>

            {/* Growth Metrics Section */}
            <Typography level="h3" sx={{ mb: 2, mt: 4 }}>Growth Metrics</Typography>
            <Grid container spacing={3} sx={{ mb: 4 }}>
                {/* User Growth */}
                <Grid xs={12} md={6}>
                    <Card sx={{ p: 2, height: '100%' }}>
                        <Typography level="h4" sx={{ mb: 2 }}>User Growth (Monthly)</Typography>
                        {userGrowthData && userGrowthData.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <LineChart data={userGrowthData}>
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis dataKey="month" />
                                    <YAxis />
                                    <Tooltip />
                                    <Line dataKey="users_registered" stroke="#3b82f6" strokeWidth={2} />
                                </LineChart>
                            </ResponsiveContainer>
                        ) : (
                            <Box sx={{ height: 300, display: "flex", alignItems: "center", justifyContent: "center" }}>
                                <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                    No user growth data available
                                </Typography>
                            </Box>
                        )}
                    </Card>
                </Grid>

                {/* Venue Growth */}
                <Grid xs={12} md={6}>
                    <Card sx={{ p: 2, height: '100%' }}>
                        <Typography level="h4" sx={{ mb: 2 }}>Venue Growth (Monthly)</Typography>
                        {venueGrowthData && venueGrowthData.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <BarChart data={venueGrowthData}>
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis dataKey="month" />
                                    <YAxis />
                                    <Tooltip />
                                    <Bar dataKey="venues_added" fill="#10b981" />
                                </BarChart>
                            </ResponsiveContainer>
                        ) : (
                            <Box sx={{ height: 300, display: "flex", alignItems: "center", justifyContent: "center" }}>
                                <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                    No venue growth data available
                                </Typography>
                            </Box>
                        )}
                    </Card>
                </Grid>
            </Grid>

            {/* Revenue Analytics Section */}
            <Typography level="h3" sx={{ mb: 2, mt: 4 }}>Revenue Analytics</Typography>
            <Grid container spacing={3} sx={{ mb: 4 }}>
                {/* Monthly Revenue */}
                <Grid xs={12} md={6}>
                    <Card sx={{ p: 2, height: '100%' }}>
                        <Typography level="h4" sx={{ mb: 2 }}>Monthly Revenue</Typography>
                        {monthlyRevenueData && monthlyRevenueData.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <LineChart data={monthlyRevenueData}>
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis dataKey="month" />
                                    <YAxis />
                                    <Tooltip formatter={(value) => [`₹${value}`, 'Revenue']} />
                                    <Line dataKey="revenue" stroke="#f59e0b" strokeWidth={2} />
                                </LineChart>
                            </ResponsiveContainer>
                        ) : (
                            <Box sx={{ height: 300, display: "flex", alignItems: "center", justifyContent: "center" }}>
                                <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                    No revenue data available
                                </Typography>
                            </Box>
                        )}
                    </Card>
                </Grid>

                {/* Revenue by Sport */}
                <Grid xs={12} md={6}>
                    <Card sx={{ p: 2, height: '100%' }}>
                        <Typography level="h4" sx={{ mb: 2 }}>Revenue by Sport</Typography>
                        {revenueBySportData && revenueBySportData.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <PieChart>
                                    <Pie
                                        data={revenueBySportData}
                                        cx="50%"
                                        cy="50%"
                                        labelLine={false}
                                        label={({ sport_name, revenue }) => `${sport_name}: ₹${revenue}`}
                                        outerRadius={80}
                                        fill="#8884d8"
                                        dataKey="revenue"
                                    >
                                        {revenueBySportData.map((entry, index) => (
                                            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                        ))}
                                    </Pie>
                                    <Tooltip formatter={(value) => [`₹${value}`, 'Revenue']} />
                                </PieChart>
                            </ResponsiveContainer>
                        ) : (
                            <Box sx={{ height: 300, display: "flex", alignItems: "center", justifyContent: "center" }}>
                                <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                    No sport revenue data available
                                </Typography>
                            </Box>
                        )}
                    </Card>
                </Grid>
            </Grid>

            {/* Booking Analytics Section */}
            <Typography level="h3" sx={{ mb: 2, mt: 4 }}>Booking Analytics</Typography>
            <Grid container spacing={3} sx={{ mb: 4 }}>
                {/* Booking Trend */}
                <Grid xs={12} md={6}>
                    <Card sx={{ p: 2, height: '100%' }}>
                        <Typography level="h4" sx={{ mb: 2 }}>Daily Booking Trend</Typography>
                        {bookingTrendData && bookingTrendData.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <BarChart data={bookingTrendData}>
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis dataKey="date" />
                                    <YAxis />
                                    <Tooltip />
                                    <Bar dataKey="total_bookings" fill="#3b82f6" />
                                </BarChart>
                            </ResponsiveContainer>
                        ) : (
                            <Box sx={{ height: 300, display: "flex", alignItems: "center", justifyContent: "center" }}>
                                <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                    No booking trend data available
                                </Typography>
                            </Box>
                        )}
                    </Card>
                </Grid>

                {/* Peak Booking Hours */}
                <Grid xs={12} md={6}>
                    <Card sx={{ p: 2, height: '100%' }}>
                        <Typography level="h4" sx={{ mb: 2 }}>Peak Booking Hours</Typography>
                        {peakBookingHoursData && peakBookingHoursData.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <BarChart data={peakBookingHoursData}>
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis dataKey="hour" />
                                    <YAxis />
                                    <Tooltip />
                                    <Bar dataKey="bookings" fill="#10b981" />
                                </BarChart>
                            </ResponsiveContainer>
                        ) : (
                            <Box sx={{ height: 300, display: "flex", alignItems: "center", justifyContent: "center" }}>
                                <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                    No peak hours data available
                                </Typography>
                            </Box>
                        )}
                    </Card>
                </Grid>
            </Grid>

            {/* Popular Content Section */}
            <Typography level="h3" sx={{ mb: 2, mt: 4 }}>Sports & Venues Analytics</Typography>
            <Grid container spacing={3} sx={{ mb: 4 }}>
                {/* Most Played Sports */}
                <Grid xs={12} md={6}>
                    <Card sx={{ p: 2, height: '100%' }}>
                        <Typography level="h4" sx={{ mb: 2 }}>Most Played Sports</Typography>
                        {mostPlayedSportsData && mostPlayedSportsData.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <BarChart data={mostPlayedSportsData}>
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis dataKey="sport_name" angle={-45} textAnchor="end" height={100} />
                                    <YAxis />
                                    <Tooltip />
                                    <Bar dataKey="total_games" fill="#8b5cf6" />
                                </BarChart>
                            </ResponsiveContainer>
                        ) : (
                            <Box sx={{ height: 300, display: "flex", alignItems: "center", justifyContent: "center" }}>
                                <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                    No sports data available
                                </Typography>
                            </Box>
                        )}
                    </Card>
                </Grid>

                {/* Most Booked Venues */}
                <Grid xs={12} md={6}>
                    <Card sx={{ p: 2, height: '100%' }}>
                        <Typography level="h4" sx={{ mb: 2 }}>Most Booked Venues</Typography>
                        {mostBookedVenuesData && mostBookedVenuesData.length > 0 ? (
                            <ResponsiveContainer width="100%" height={300}>
                                <BarChart data={mostBookedVenuesData} layout="vertical">
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis type="number" />
                                    <YAxis type="category" dataKey="venue_name" width={150} />
                                    <Tooltip />
                                    <Bar dataKey="booking_count" fill="#06b6d4" />
                                </BarChart>
                            </ResponsiveContainer>
                        ) : (
                            <Box sx={{ height: 300, display: "flex", alignItems: "center", justifyContent: "center" }}>
                                <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                    No venue data available
                                </Typography>
                            </Box>
                        )}
                    </Card>
                </Grid>
            </Grid>

            {/* Top Users & Content Section */}
            <Typography level="h3" sx={{ mb: 2, mt: 4 }}>User Analytics</Typography>
            <Grid container spacing={3} sx={{ mb: 4 }}>
                {/* Top Users by Bookings */}
                <Grid xs={12} md={4}>
                    <Card sx={{ p: 2, height: '100%' }}>
                        <Typography level="h4" sx={{ mb: 2 }}>Top Users by Bookings</Typography>
                        {topUsersByBookingsData && topUsersByBookingsData.length > 0 ? (
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                                {topUsersByBookingsData.map((user, index) => (
                                    <Box key={index} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', p: 1, bgcolor: 'background.level1', borderRadius: 'sm' }}>
                                        <Typography level="body-sm">
                                            {user.first_name} {user.last_name}
                                        </Typography>
                                        <Typography level="body-xs" sx={{ color: 'primary.500', fontWeight: 'bold' }}>
                                            {user.total_bookings} bookings
                                        </Typography>
                                    </Box>
                                ))}
                            </Box>
                        ) : (
                            <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                No user data available
                            </Typography>
                        )}
                    </Card>
                </Grid>

                {/* Top Content Creators */}
                <Grid xs={12} md={4}>
                    <Card sx={{ p: 2, height: '100%' }}>
                        <Typography level="h4" sx={{ mb: 2 }}>Top Content Creators</Typography>
                        {topContentCreatorsData && topContentCreatorsData.length > 0 ? (
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                                {topContentCreatorsData.map((creator, index) => (
                                    <Box key={index} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', p: 1, bgcolor: 'background.level1', borderRadius: 'sm' }}>
                                        <Typography level="body-sm">
                                            {creator.first_name} {creator.last_name}
                                        </Typography>
                                        <Typography level="body-xs" sx={{ color: 'success.500', fontWeight: 'bold' }}>
                                            {creator.posts_count} posts
                                        </Typography>
                                    </Box>
                                ))}
                            </Box>
                        ) : (
                            <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                No creator data available
                            </Typography>
                        )}
                    </Card>
                </Grid>

                {/* Most Liked Posts */}
                <Grid xs={12} md={4}>
                    <Card sx={{ p: 2, height: '100%' }}>
                        <Typography level="h4" sx={{ mb: 2 }}>Most Liked Posts</Typography>
                        {mostLikedPostsData && mostLikedPostsData.length > 0 ? (
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                                {mostLikedPostsData.map((post, index) => (
                                    <Box key={index} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', p: 1, bgcolor: 'background.level1', borderRadius: 'sm' }}>
                                        <Typography level="body-sm">
                                            {post.first_name} {post.last_name}
                                        </Typography>
                                        <Typography level="body-xs" sx={{ color: 'danger.500', fontWeight: 'bold' }}>
                                            ❤️ {post.likes}
                                        </Typography>
                                    </Box>
                                ))}
                            </Box>
                        ) : (
                            <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                No post data available
                            </Typography>
                        )}
                    </Card>
                </Grid>
            </Grid>

            {/* Revenue Breakdown Section */}
            <Typography level="h3" sx={{ mb: 2, mt: 4 }}>Revenue Breakdown</Typography>
            <Grid container spacing={3} sx={{ mb: 4 }}>
                {/* Revenue by Venue */}
                <Grid xs={12}>
                    <Card sx={{ p: 2 }}>
                        <Typography level="h4" sx={{ mb: 2 }}>Revenue by Venue</Typography>
                        {revenueByVenueData && revenueByVenueData.length > 0 ? (
                            <ResponsiveContainer width="100%" height={400}>
                                <BarChart data={revenueByVenueData}>
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis dataKey="venue_name" angle={-45} textAnchor="end" height={100} />
                                    <YAxis />
                                    <Tooltip formatter={(value) => [`₹${value}`, 'Revenue']} />
                                    <Bar dataKey="revenue" fill="#f97316" />
                                </BarChart>
                            </ResponsiveContainer>
                        ) : (
                            <Box sx={{ height: 400, display: "flex", alignItems: "center", justifyContent: "center" }}>
                                <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                    No venue revenue data available
                                </Typography>
                            </Box>
                        )}
                    </Card>
                </Grid>
            </Grid>

            {/* Legacy Charts (for backward compatibility) */}
            {(userData.length > 0 || bookingData.length > 0 || revenueData.length > 0) && (
                <>
                    <Divider sx={{ my: 4 }} />
                    <Typography level="h3" sx={{ mb: 2 }}>📊 Legacy Reports</Typography>

                    {userData.length > 0 && (
                        <Card sx={{ mb: 3, p: 2 }}>
                            <Typography level="h4">Legacy User Growth</Typography>
                            <ResponsiveContainer width="100%" height={300}>
                                <LineChart data={userData}>
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis dataKey="date" />
                                    <YAxis />
                                    <Tooltip />
                                    <Line dataKey="users" stroke="#3b82f6" strokeWidth={2} />
                                </LineChart>
                            </ResponsiveContainer>
                        </Card>
                    )}

                    {bookingData.length > 0 && (
                        <Card sx={{ mb: 3, p: 2 }}>
                            <Typography level="h4">Legacy Bookings Trend</Typography>
                            <ResponsiveContainer width="100%" height={300}>
                                <BarChart data={bookingData}>
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis dataKey="date" />
                                    <YAxis />
                                    <Tooltip />
                                    <Bar dataKey="bookings" fill="#10b981" />
                                </BarChart>
                            </ResponsiveContainer>
                        </Card>
                    )}

                    {revenueData.length > 0 && (
                        <Card sx={{ p: 2 }}>
                            <Typography level="h4">Legacy Revenue Trend</Typography>
                            <ResponsiveContainer width="100%" height={300}>
                                <LineChart data={revenueData}>
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis dataKey="date" />
                                    <YAxis />
                                    <Tooltip />
                                    <Line dataKey="revenue" stroke="#f59e0b" strokeWidth={2} />
                                </LineChart>
                            </ResponsiveContainer>
                        </Card>
                    )}
                </>
            )}
        </Box>
    );
}

export default AdminAnalytics;

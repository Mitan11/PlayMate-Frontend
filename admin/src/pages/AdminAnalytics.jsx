import React, { useEffect, useMemo, useState } from "react";
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
import Modal from "@mui/joy/Modal";
import ModalDialog from "@mui/joy/ModalDialog";
import Button from "@mui/joy/Button";
import { useDispatch, useSelector } from "react-redux";
import {
    selectAnalyticsBookingData,
    selectAnalyticsError,
    selectAnalyticsRevenueData,
    selectAnalyticsStatus,
    selectAnalyticsUserData,
    selectBookingTrendData,
    selectMostBookedVenuesData,
    selectMostLikedPostsData,
    selectMostPlayedSportsData,
    selectMonthlyRevenueData,
    selectPeakBookingHoursData,
    selectRevenueBySportData,
    selectRevenueByVenueData,
    selectTopContentCreatorsData,
    selectTopUsersByBookingsData,
    selectUserGrowthData,
    selectVenueGrowthData,
} from "../features/analytics/analyticsSelectors";
import { fetchAnalytics } from "../features/analytics/analyticsThunks";
import { clearAnalyticsError as clearAnalyticsErrorAction } from "../features/analytics/analyticsSlice";

function AdminAnalytics() {
    const dispatch = useDispatch();

    const bookingData = useSelector(selectAnalyticsBookingData);
    const revenueData = useSelector(selectAnalyticsRevenueData);
    const userData = useSelector(selectAnalyticsUserData);
    const userGrowthData = useSelector(selectUserGrowthData);
    const venueGrowthData = useSelector(selectVenueGrowthData);
    const bookingTrendData = useSelector(selectBookingTrendData);
    const monthlyRevenueData = useSelector(selectMonthlyRevenueData);
    const revenueByVenueData = useSelector(selectRevenueByVenueData);
    const revenueBySportData = useSelector(selectRevenueBySportData);
    const mostPlayedSportsData = useSelector(selectMostPlayedSportsData);
    const mostBookedVenuesData = useSelector(selectMostBookedVenuesData);
    const peakBookingHoursData = useSelector(selectPeakBookingHoursData);
    const topUsersByBookingsData = useSelector(selectTopUsersByBookingsData);
    const mostLikedPostsData = useSelector(selectMostLikedPostsData);
    const topContentCreatorsData = useSelector(selectTopContentCreatorsData);
    const status = useSelector(selectAnalyticsStatus);
    const error = useSelector(selectAnalyticsError);
    const loading = status === "loading" || status === "idle";
    
    // Modal state for post details
    const [selectedPost, setSelectedPost] = useState(null);
    const [modalOpen, setModalOpen] = useState(false);

    useEffect(() => {
        dispatch(fetchAnalytics());
    }, [dispatch]);

    useEffect(() => {
        if (error) {
            toast.error(error);
            dispatch(clearAnalyticsErrorAction());
        }
    }, [error, dispatch]);

    // Color palette for charts
    const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#84cc16', '#f97316'];

    // Handle post click to show details
    const handlePostClick = (post) => {
        setSelectedPost(post);
        setModalOpen(true);
    };

    // Handle modal close
    const handleCloseModal = () => {
        setModalOpen(false);
        setSelectedPost(null);
    };

    if (loading) {
        return (
            <Preloader />
        );
    }

    return (
        <Box sx={{ p: 3, maxWidth: '100%', overflow: 'hidden' }}>
            <Box sx={{ mb: 3, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <Typography level="h2">Comprehensive Analytics Dashboard</Typography>
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
                                    <Box 
                                        key={index} 
                                        onClick={() => handlePostClick(post)}
                                        sx={{ 
                                            display: 'flex', 
                                            justifyContent: 'space-between', 
                                            alignItems: 'center', 
                                            p: 1, 
                                            bgcolor: 'background.level1', 
                                            borderRadius: 'sm',
                                            cursor: 'pointer',
                                            transition: 'all 0.2s ease',
                                            '&:hover': {
                                                bgcolor: 'background.level2',
                                                boxShadow: 'sm',
                                                transform: 'translateY(-2px)'
                                            }
                                        }}
                                    >
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

            {/* Modal for Post Details */}
            <Modal 
                open={modalOpen} 
                onClose={handleCloseModal}
                sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}
            >
                <ModalDialog
                    layout="center"
                    size="md"
                    sx={{ 
                        maxWidth: 600,
                        borderRadius: 'md',
                        p: 3
                    }}
                >
                    <Box sx={{ mb: 2 }}>
                        <Typography level="h3" sx={{ mb: 2 }}>
                            {selectedPost?.first_name} {selectedPost?.last_name}'s Post
                        </Typography>
                        <Divider />
                    </Box>

                    {selectedPost && (
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                            {/* Post Content */}
                            <Box>
                                <Typography level="body-sm" sx={{ color: 'neutral.600', mb: 1 }}>
                                    <strong>Content:</strong>
                                </Typography>
                                <Typography level="body-md" sx={{ p: 1.5, bgcolor: 'background.level1', borderRadius: 'sm' }}>
                                    {selectedPost.text_content || 'No content available'}
                                </Typography>
                            </Box>

                            {/* Post Media */}
                            {selectedPost.media_url && (
                                <Box>
                                    <Typography level="body-sm" sx={{ color: 'neutral.600', mb: 1 }}>
                                        <strong>Media:</strong>
                                    </Typography>
                                    <Box
                                        component="img"
                                        src={selectedPost.media_url}
                                        alt="Post media"
                                        sx={{
                                            maxWidth: '100%',
                                            height: 'auto',
                                            borderRadius: 'sm',
                                            maxHeight: 300
                                        }}
                                    />
                                </Box>
                            )}

                            {/* Created Date */}
                            <Box>
                                <Typography level="body-sm" sx={{ color: 'neutral.600', mb: 1 }}>
                                    <strong>Posted on:</strong>
                                </Typography>
                                <Typography level="body-md">
                                    {selectedPost.created_at ? new Date(selectedPost.created_at).toLocaleString() : 'Unknown'}
                                </Typography>
                            </Box>

                            {/* Like Count */}
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, bgcolor: 'danger.softBg', p: 1.5, borderRadius: 'sm' }}>
                                <Typography level="body-md">
                                    ❤️ {selectedPost.likes} {selectedPost.likes === 1 ? 'like' : 'likes'}
                                </Typography>
                            </Box>
                        </Box>
                    )}

                    <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 1, mt: 3 }}>
                        <Button variant="plain" color="neutral" onClick={handleCloseModal}>
                            Close
                        </Button>
                    </Box>
                </ModalDialog>
            </Modal>
        </Box>
    );
}

export default AdminAnalytics;

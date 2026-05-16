import axios from "axios";

const API_URL = import.meta.env.VITE_BACKEND_URL || "http://localhost:4000/api/v1";

const getAuthHeaders = (token) => ({
    Authorization: `Bearer ${token}`,
});

export const analyticsApi = {
    fetchAnalytics: async (token) => {
        const headers = getAuthHeaders(token);

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
            bookingRes,
            revenueRes,
            userRes,
        ] = await Promise.all([
            axios.get(`${API_URL}/admin/analytics/user-growth`, { headers }),
            axios.get(`${API_URL}/admin/analytics/venue-growth`, { headers }),
            axios.get(`${API_URL}/admin/analytics/booking-trend`, { headers }),
            axios.get(`${API_URL}/admin/analytics/monthly-revenue`, { headers }),
            axios.get(`${API_URL}/admin/analytics/revenue-by-venue`, { headers }),
            axios.get(`${API_URL}/admin/analytics/revenue-by-sport`, { headers }),
            axios.get(`${API_URL}/admin/analytics/most-played-sports`, { headers }),
            axios.get(`${API_URL}/admin/analytics/most-booked-venues`, { headers }),
            axios.get(`${API_URL}/admin/analytics/peak-booking-hours`, { headers }),
            axios.get(`${API_URL}/admin/analytics/top-users-by-bookings`, { headers }),
            axios.get(`${API_URL}/admin/analytics/most-liked-posts`, { headers }),
            axios.get(`${API_URL}/admin/analytics/top-content-creators`, { headers }),
            axios.get(`${API_URL}/admin/dashboard/booking/report`, { headers }).catch(() => ({ data: { data: [] } })),
            axios.get(`${API_URL}/admin/dashboard/revenue/report`, { headers }).catch(() => ({ data: { data: [] } })),
            axios.get(`${API_URL}/admin/dashboard/user/report`, { headers }).catch(() => ({ data: { data: [] } })),
        ]);

        const formatMonthlyData = (data, valueKey) =>
            data.map((item) => ({
                month: item.month,
                value: item[valueKey],
                [valueKey]: item[valueKey],
            }));

        const formatDailyData = (data, valueKey) =>
            data.map((item) => ({
                date: new Date(item.date).toLocaleDateString(),
                value: item[valueKey],
                [valueKey]: item[valueKey],
            }));

        const formatHourlyData = (data) =>
            data.map((item) => ({
                hour: `${item.hour}:00`,
                bookings: item.bookings,
                value: item.bookings,
            }));

        const processRevenueData = (data) =>
            data.map((item) => ({
                ...item,
                revenue: parseFloat(item.revenue) || 0,
            }));

        return {
            userGrowthData: formatMonthlyData(userGrowthRes.data.data || [], "users_registered"),
            venueGrowthData: formatMonthlyData(venueGrowthRes.data.data || [], "venues_added"),
            bookingTrendData: formatDailyData(bookingTrendRes.data.data || [], "total_bookings"),
            monthlyRevenueData: formatMonthlyData(monthlyRevenueRes.data.data || [], "revenue"),
            revenueByVenueData: processRevenueData(revenueByVenueRes.data.data || []),
            revenueBySportData: processRevenueData(revenueBySportRes.data.data || []),
            mostPlayedSportsData: mostPlayedSportsRes.data.data || [] ,
            mostBookedVenuesData: mostBookedVenuesRes.data.data || [],
            peakBookingHoursData: formatHourlyData(peakBookingHoursRes.data.data || []),
            topUsersByBookingsData: topUsersByBookingsRes.data.data || [],
            mostLikedPostsData: mostLikedPostsRes.data.data || [],
            topContentCreatorsData: topContentCreatorsRes.data.data || [],
            bookingData: bookingRes.data.data || [],
            revenueData: revenueRes.data.data || [],
            userData: userRes.data.data || [],
        };
    },
};

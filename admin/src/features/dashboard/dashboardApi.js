import axios from "axios";

const API_URL = import.meta.env.VITE_BACKEND_URL || "http://localhost:4000/api/v1";

const getAuthHeaders = (token) => ({
    Authorization: `Bearer ${token}`,
});

export const dashboardApi = {
    fetchDashboardData: async (token) => {
        const headers = getAuthHeaders(token);

        const [statsRes, metricsRes, activitiesRes] = await Promise.all([
            axios.get(`${API_URL}/admin/dashboard/stats`, { headers }),
            axios.get(`${API_URL}/admin/dashboard/sport/metrics`, { headers }),
            axios.get(`${API_URL}/admin/dashboard/recent/activities`, { headers }),
        ]);

        return {
            stats: statsRes.data?.data ?? null,
            sportMetrics: metricsRes.data?.data ?? [],
            recentActivities: activitiesRes.data?.data ?? [],
        };
    },
};

import React, { useEffect, useState, useContext, useMemo } from "react";
import axios from "axios";
import { AppContext } from "../context/AppContextProvider";
import { toast } from "react-hot-toast";

import {
    LineChart, Line, BarChart, Bar,
    XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from "recharts";

import Box from "@mui/joy/Box";
import Card from "@mui/joy/Card";
import Typography from "@mui/joy/Typography";
import Select from "@mui/joy/Select";
import Option from "@mui/joy/Option";

function AdminAnalytics() {
    const { backendUrl, aToken } = useContext(AppContext);

    const [bookingData, setBookingData] = useState([]);
    const [revenueData, setRevenueData] = useState([]);
    const [userData, setUserData] = useState([]);
    const [range, setRange] = useState("daily");

    useEffect(() => {
        fetchReports();
    }, []);

    const fetchReports = async () => {
        try {
            const headers = { Authorization: `Bearer ${aToken}` };

            const [b, r, u] = await Promise.all([
                axios.get(`${backendUrl}/admin/dashboard/booking/report`, { headers }),
                axios.get(`${backendUrl}/admin/dashboard/revenue/report`, { headers }),
                axios.get(`${backendUrl}/admin/dashboard/user/report`, { headers }),
            ]);

            setBookingData(formatData(b.data.data));
            setRevenueData(formatData(r.data.data, "revenue"));
            setUserData(formatData(u.data.data, "users"));
        } catch {
            toast.error("Failed to load analytics");
        }
    };

    // Format API data → chart friendly
    const formatData = (data, key = "bookings") =>
        data.map(item => ({
            date: new Date(item.date).toLocaleDateString(),
            [key]: item[key] ?? item.users ?? item.bookings
        }));

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

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ mb: 3, display: "flex", justifyContent: "space-between" }}>
                <Typography level="h2">Analytics & Reports</Typography>
                <Select value={range} onChange={(_, v) => setRange(v)}>
                    <Option value="daily">Daily</Option>
                    <Option value="monthly">Monthly</Option>
                </Select>
            </Box>

            {/* USER GROWTH */}
            <Card sx={{ mb: 3, p: 2 }}>
                <Typography level="h4">User Growth</Typography>
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

            {/* BOOKINGS */}
            <Card sx={{ mb: 3, p: 2 }}>
                <Typography level="h4">Bookings Trend</Typography>
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

            {/* REVENUE */}
            <Card sx={{ p: 2 }}>
                <Typography level="h4">Revenue Trend</Typography>
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
        </Box>
    );
}

export default AdminAnalytics;

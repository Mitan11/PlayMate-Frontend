import { createAsyncThunk } from "@reduxjs/toolkit";
import { dashboardApi } from "./dashboardApi";

const getToken = (state) => state.auth.token;

export const fetchDashboardData = createAsyncThunk(
    "dashboard/fetchDashboardData",
    async (_, { getState, rejectWithValue }) => {
        try {
            const token = getToken(getState());
            return await dashboardApi.fetchDashboardData(token);
        } catch (error) {
            return rejectWithValue(error?.response?.data?.message || "Failed to load dashboard data");
        }
    }
);

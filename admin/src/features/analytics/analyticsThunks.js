import { createAsyncThunk } from "@reduxjs/toolkit";
import { analyticsApi } from "./analyticsApi";

const getToken = (state) => state.auth.token;

export const fetchAnalytics = createAsyncThunk(
    "analytics/fetchAnalytics",
    async (_, { getState, rejectWithValue }) => {
        try {
            const token = getToken(getState());
            return await analyticsApi.fetchAnalytics(token);
        } catch (error) {
            return rejectWithValue(error?.response?.data?.message || "Failed to load analytics data");
        }
    }
);

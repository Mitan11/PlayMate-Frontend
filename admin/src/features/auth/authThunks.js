import { createAsyncThunk } from "@reduxjs/toolkit";
import { authApi } from "./authApi";

export const adminLogin = createAsyncThunk(
    "auth/adminLogin",
    async ({ email, password }, { rejectWithValue }) => {
        try {
            const data = await authApi.adminLogin(email, password);
            if (data.token) {
                localStorage.setItem("aToken", data.token);
            }
            return data;
        } catch (error) {
            return rejectWithValue(
                error?.response?.data?.message || "Login failed"
            );
        }
    }
);
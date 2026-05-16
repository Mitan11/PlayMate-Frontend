import { createSlice } from "@reduxjs/toolkit";
import { adminLogin } from "./authThunks";

const initialState = {
    adminUser: null,
    token: localStorage.getItem("aToken") || null,
    status: "idle",
    error: null,
};

export const authSlice = createSlice({
    name: "auth",
    initialState,
    reducers: {
        logout: (state) => {
            state.adminUser = null;
            state.token = null;
            state.error = null;
            localStorage.removeItem("aToken");
        },
        clearError: (state) => {
            state.error = null;
        },
    },
    extraReducers: (builder) => {
        builder
            .addCase(adminLogin.pending, (state) => {
                state.status = "loading";
                state.error = null;
            })
            .addCase(adminLogin.fulfilled, (state, action) => {
                state.status = "succeeded";
                state.token = action.payload.token;
                state.adminUser = action.payload.data;
                state.error = null;
            })
            .addCase(adminLogin.rejected, (state, action) => {
                state.status = "failed";
                state.error = action.payload || "Login failed";
                state.token = null;
                state.adminUser = null;
            });
    },
});

export const { logout, clearError } = authSlice.actions;
export default authSlice.reducer;

import { createAsyncThunk } from "@reduxjs/toolkit";
import { usersApi } from "./usersApi";

const getToken = (state) => state.auth.token;

export const fetchUsers = createAsyncThunk(
    "users/fetchUsers",
    async (_, { getState, rejectWithValue }) => {
        try {
            const token = getToken(getState());
            const data = await usersApi.fetchUsers(token);
            return data.data || [];
        } catch (error) {
            return rejectWithValue(error?.response?.data?.message || "Failed to fetch users");
        }
    }
);

export const removeUser = createAsyncThunk(
    "users/removeUser",
    async (userId, { getState, rejectWithValue }) => {
        try {
            const token = getToken(getState());
            await usersApi.deleteUser(token, userId);
            return userId;
        } catch (error) {
            return rejectWithValue(error?.response?.data?.message || "Failed to delete user");
        }
    }
);

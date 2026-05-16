import { createAsyncThunk } from "@reduxjs/toolkit";
import { postsApi } from "./postsApi";

const getToken = (state) => state.auth.token;

export const fetchPosts = createAsyncThunk(
    "posts/fetchPosts",
    async (_, { getState, rejectWithValue }) => {
        try {
            const token = getToken(getState());
            const data = await postsApi.fetchPosts(token);
            return data.data || [];
        } catch (error) {
            return rejectWithValue(error?.response?.data?.message || "Failed to fetch posts");
        }
    }
);

export const removePost = createAsyncThunk(
    "posts/removePost",
    async (postId, { getState, rejectWithValue }) => {
        try {
            const token = getToken(getState());
            await postsApi.deletePost(token, postId);
            return postId;
        } catch (error) {
            return rejectWithValue(error?.response?.data?.message || "Failed to delete post");
        }
    }
);

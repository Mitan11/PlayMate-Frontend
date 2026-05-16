import { createSlice } from "@reduxjs/toolkit";
import { fetchPosts, removePost } from "./postsThunks";

const initialState = {
    posts: [],
    status: "idle",
    error: null,
};

const setPending = (state) => {
    state.status = "loading";
    state.error = null;
};

const setRejected = (state, action) => {
    state.status = "failed";
    state.error = action.payload || action.error?.message || "Something went wrong";
};

export const postsSlice = createSlice({
    name: "posts",
    initialState,
    reducers: {
        clearPostsError: (state) => {
            state.error = null;
        },
    },
    extraReducers: (builder) => {
        builder
            .addCase(fetchPosts.pending, setPending)
            .addCase(fetchPosts.fulfilled, (state, action) => {
                state.status = "succeeded";
                state.posts = action.payload;
            })
            .addCase(fetchPosts.rejected, setRejected)
            .addCase(removePost.pending, setPending)
            .addCase(removePost.fulfilled, (state, action) => {
                state.status = "succeeded";
                state.posts = state.posts.filter((post) => post.post_id !== action.payload);
            })
            .addCase(removePost.rejected, setRejected);
    },
});

export const { clearPostsError } = postsSlice.actions;
export default postsSlice.reducer;

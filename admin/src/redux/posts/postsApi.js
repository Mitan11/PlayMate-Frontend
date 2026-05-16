import axios from "axios";

const API_URL = import.meta.env.VITE_BACKEND_URL || "http://localhost:4000/api/v1";

const getAuthHeaders = (token) => ({
    Authorization: `Bearer ${token}`,
});

export const postsApi = {
    fetchPosts: async (token) => {
        const response = await axios.get(`${API_URL}/admin/getAllPosts`, {
            headers: getAuthHeaders(token),
        });
        return response.data;
    },
    deletePost: async (token, postId) => {
        const response = await axios.delete(`${API_URL}/admin/deletePost/${postId}`, {
            headers: getAuthHeaders(token),
        });
        return response.data;
    },
};

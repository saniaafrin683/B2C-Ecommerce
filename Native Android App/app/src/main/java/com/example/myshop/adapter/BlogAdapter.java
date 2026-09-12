package com.example.myshop.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.myshop.R;
import com.example.myshop.model.BlogPost;
import com.example.myshop.network.RetrofitClient;

import java.util.List;

public class BlogAdapter extends RecyclerView.Adapter<BlogAdapter.BlogViewHolder> {
    private final List<BlogPost> blogPosts;
    private final OnBlogClickListener clickListener;

    public interface OnBlogClickListener {
        void onBlogClick(BlogPost blogPost);
    }

    public BlogAdapter(List<BlogPost> blogPosts, OnBlogClickListener clickListener) {
        this.blogPosts = blogPosts;
        this.clickListener = clickListener;
    }

    @NonNull
    @Override
    public BlogViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_blog, parent, false);
        return new BlogViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull BlogViewHolder holder, int position) {
        BlogPost blogPost = blogPosts.get(position);
        Glide.with(holder.itemView.getContext())
                .load(buildImageUrl(blogPost.getImageUrl()))
                .placeholder(blogPost.getImageResId())
                .error(blogPost.getImageResId())
                .centerCrop()
                .into(holder.imageView);
        holder.titleText.setText(blogPost.getTitle());
        holder.descriptionText.setText(blogPost.getShortDescription());
        holder.dateText.setText(blogPost.getDate());
        holder.categoryText.setText(blogPost.getCategory());

        View.OnClickListener listener = view -> {
            if (clickListener != null) {
                clickListener.onBlogClick(blogPost);
            }
        };
        holder.itemView.setOnClickListener(listener);
        holder.readMoreButton.setOnClickListener(listener);
    }

    @Override
    public int getItemCount() {
        return blogPosts == null ? 0 : blogPosts.size();
    }

    private String buildImageUrl(String imageUrl) {
        if (imageUrl == null || imageUrl.trim().isEmpty()) {
            return null;
        }
        String value = imageUrl.trim();
        if (value.startsWith("http://") || value.startsWith("https://") || value.startsWith("data:")) {
            return value;
        }
        return RetrofitClient.getBaseUrl() + value.replaceFirst("^/+", "");
    }

    static class BlogViewHolder extends RecyclerView.ViewHolder {
        private final ImageView imageView;
        private final TextView titleText;
        private final TextView descriptionText;
        private final TextView dateText;
        private final TextView categoryText;
        private final Button readMoreButton;

        BlogViewHolder(@NonNull View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.blogImageView);
            titleText = itemView.findViewById(R.id.blogTitleText);
            descriptionText = itemView.findViewById(R.id.blogDescriptionText);
            dateText = itemView.findViewById(R.id.blogDateText);
            categoryText = itemView.findViewById(R.id.blogCategoryText);
            readMoreButton = itemView.findViewById(R.id.blogReadMoreButton);
        }
    }
}

package com.aliyun.artc.api.example.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import com.aliyun.artc.api.example.R;
import com.aliyun.artc.api.example.bean.ApiModuleInfo;

import java.util.ArrayList;
import java.util.List;

public class APIExampleListAdapter extends RecyclerView.Adapter{
    private List<ApiModuleInfo> topicList = new ArrayList<>();
    private ListOnItemClickListener mOnItemClickListener;

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.api_module_list, parent, false);
        return new MyViewHolder(v);
    }

    @Override
    public void onBindViewHolder(final RecyclerView.ViewHolder holder, int position) {
        final MyViewHolder myViewHolder = (MyViewHolder) holder;
        if (mOnItemClickListener != null) {
            myViewHolder.list.setOnClickListener(v -> {
                if (mOnItemClickListener != null) {
                    int position1 = myViewHolder.getLayoutPosition();
                    v.setTag(topicList.get(position1));
                    mOnItemClickListener.onItemClick(v, position1);
                }
            });
        }
        ApiModuleInfo moduleInfo = topicList.get(position);
        if (moduleInfo.getTitleName() != null) {
            myViewHolder.title.setVisibility(View.VISIBLE);
            myViewHolder.titleName.setText(moduleInfo.getTitleName());
        } else {
            myViewHolder.title.setVisibility(View.GONE);
        }

        myViewHolder.name.setText(moduleInfo.getModule());
    }

    @Override
    public int getItemCount() {
        return topicList.size();
    }

    /**
     * 新增模块信息
     *
     * @param moduleInfo module info
     */
    public void addModuleInfo(ApiModuleInfo moduleInfo) {
        topicList.add(moduleInfo);
        notifyDataSetChanged();
    }

    public void clear() {
        topicList.clear();
    }

    public static class MyViewHolder extends RecyclerView.ViewHolder {
        RelativeLayout list;
        TextView name;
        TextView titleName;
        RelativeLayout title;

        MyViewHolder(View itemView) {
            super(itemView);
            list = itemView.findViewById(R.id.api_list);
            name = itemView.findViewById(R.id.api_name);
            titleName = itemView.findViewById(R.id.api_title_name);
            title = itemView.findViewById(R.id.api_title);
        }
    }

    public void setOnItemClickListener(ListOnItemClickListener mOnItemClickListener) {
        this.mOnItemClickListener = mOnItemClickListener;
    }

    public interface ListOnItemClickListener {
        void onItemClick(View view, int position);
    }

}

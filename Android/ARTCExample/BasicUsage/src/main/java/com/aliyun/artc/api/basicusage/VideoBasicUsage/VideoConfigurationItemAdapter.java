package com.aliyun.artc.api.basicusage.VideoBasicUsage;

import android.content.Context;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.Switch;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.SwitchCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.aliyun.artc.api.basicusage.R;

import java.util.List;

public class VideoConfigurationItemAdapter extends RecyclerView.Adapter<VideoConfigurationItemAdapter.VideoConfigurationViewHolder> {
    private List<VideoConfigurationItem> items;
    private Context context;

    public VideoConfigurationItemAdapter(Context context, List<VideoConfigurationItem> items) {
        this.items = items;
        this.context = context;
    }

    @Override
    public int getItemViewType(int position) {
        return items.get(position).type;
    }

    @NonNull
    @Override
    public VideoConfigurationViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        if(viewType == VideoConfigurationItem.TYPE_HEADER) {
            TextView textView = new TextView(context);
            textView.setTextSize(16);
            textView.setBackgroundColor(0xFFE0E0E0);
            textView.setPadding(20, 20, 20, 20);
            textView.setGravity(Gravity.CENTER_VERTICAL);
            textView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
            return new VideoConfigurationViewHolder(textView);
        }

        View view = LayoutInflater.from(context).inflate(R.layout.video_configuration_item, parent, false);
        return new VideoConfigurationViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull VideoConfigurationViewHolder holder, int position) {
        VideoConfigurationItem item = items.get(position);
        // 类别
        if(item.type == VideoConfigurationItem.TYPE_HEADER) {
            ((TextView) holder.itemView).setText(item.title);
            return;
        }
        holder.title.setText(item.title);
        holder.switchControl.setVisibility(View.GONE);
        holder.editText.setVisibility(View.GONE);
        holder.spinner.setVisibility(View.GONE);

        switch (item.type) {
            case VideoConfigurationItem.TYPE_SWITCH:
                holder.switchControl.setVisibility(View.VISIBLE);
                holder.switchControl.setOnCheckedChangeListener(null);
                holder.switchControl.setChecked(item.switchValue);
                holder.switchControl.setOnCheckedChangeListener((buttonView, isChecked) -> {
                    item.switchValue = isChecked;
                });
                break;
            case VideoConfigurationItem.TYPE_EDIT_TEXT:
                holder.editText.setVisibility(View.VISIBLE);
                TextWatcher oldWatcher = (TextWatcher) holder.editText.getTag();
                if (oldWatcher != null) {
                    holder.editText.removeTextChangedListener(oldWatcher);
                }
                holder.editText.setText(item.editTextValue);
                TextWatcher watcher = new TextWatcher() {
                    @Override
                    public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

                    @Override
                    public void onTextChanged(CharSequence s, int start, int before, int count) {}

                    @Override
                    public void afterTextChanged(Editable s) {
                        item.editTextValue = s.toString();
                    }
                };
                holder.editText.addTextChangedListener(watcher);
                holder.editText.setTag(watcher);
                break;
            case VideoConfigurationItem.TYPE_SPINNER:
                holder.spinner.setVisibility(View.VISIBLE);
                ArrayAdapter<String> adapter = new ArrayAdapter<>(context, android.R.layout.simple_spinner_item, item.spinnerOptions);
                adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                holder.spinner.setAdapter(adapter);
                if(item.spinnerIndex >= 0 && item.spinnerIndex < item.spinnerOptions.size()) {
                    holder.spinner.setSelection(item.spinnerIndex);
                } else {
                    holder.spinner.setSelection(0);
                }
                holder.spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                    @Override
                    public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                        item.spinnerIndex = position;
                        if (item.spinnerOptions != null && position >= 0 && position < item.spinnerOptions.size()) {
                            item.spinnerValue = item.spinnerOptions.get(position);
                        }
                    }

                    @Override
                    public void onNothingSelected(AdapterView<?> parent) {
                        // Do nothing
                    }
                });

                break;
            default:
                break;
        }
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    static class VideoConfigurationViewHolder extends RecyclerView.ViewHolder {

        TextView title;
        SwitchCompat switchControl;
        EditText editText;
        Spinner spinner;
        public VideoConfigurationViewHolder(@NonNull View itemView) {
            super(itemView);
            title = itemView.findViewById(R.id.config_title);
            switchControl = itemView.findViewById(R.id.config_switch_control);
            editText = itemView.findViewById(R.id.config_edit_text);
            spinner = itemView.findViewById(R.id.config_spinner);
        }
    }
}

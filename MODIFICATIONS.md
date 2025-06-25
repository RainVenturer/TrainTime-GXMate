# GXMU PDA 修改记录

本文档记录了对原始 Traintime PDA 项目的所有重要修改。

## 主要修改

### 系统适配
- 修改了网络会话模块以适配广西医科大学教务系统
- 更新了认证流程以匹配广西医科大学的登录系统
- 调整了数据解析逻辑以适应广西医科大学的数据格式

### 功能变更
- 移除了西电特有的功能：
  - XDU Planet（校园博客）
  - 实验查看
  - 电费查询相关
  - 校园网用量查询
  - 图书馆系列功能
  - 校园卡查询
  - 体育系统
  - 考试系统

### 国际化
- 保留了原有的中文（简体、繁体）和英文支持
- 更新了所有与学校相关的翻译内容

## 文件修改记录

### 新增文件
- `MODIFICATIONS.md`：本文件，用于记录修改
- `lib\repository\captcha\captcha_solver.dart`: 一站式登录的验证码识别
- `lib\repository\rsa_encryption.dart`: 一站式登录的 RSA 加密
- `assets\captcha-solver-cas.tflite`: 一站式验证码识别模型

### 主要修改的文件
- `lib/repository/*`：适配广西医科大学
- `lib/repository/gxmu_ids/*`：适配广西医科大学信息获取
- `lib/page/classtable/*`：适配广西医科大学课表
- `lib/page/score/*`：适配广西医科大学成绩查询
- `lib/page/setting/about_page/about_page.dart`：更新版权信息和应用标识
- `lib\model\gxmu_ids`：适配广西医科大学信息数据结构
- `README.md`：更新项目说明文档

### 删除的文件
- `lib/repository/*`：删除西电特有的信息获取
- `lib/page/experiment/*`：删除物理实验相关页面
- `lib/page/sport/*`：删除体育系统相关页面
- `lib/page/library/*`：删除图书馆相关页面
- `lib/page/schoolnet/*`：删除校园网相关页面
- `lib/page/electricity/*`：删除电费查询相关页面
- `lib/page/schoolcard/*`：删除校园卡相关页面
- `lib/page/exam/*`：删除考试系统相关页面
- `lib/page/sport_system/*`：删除体育系统相关页面
- `lib/controller/exam_controller.dart`：删除考试系统相关页面
- `lib/controller/experiment_controller.dart`：删除实验相关页面

## 版权和许可

所有修改均遵循 MPL-2.0 许可证。每个修改过的文件都包含了适当的版权声明和许可证信息。

## 贡献者

- [RainVenturer]：项目适配和维护
- [Yang-ZhiHang]：验证码识别模型训练

## 更新日志

### [1.0.0] - [2025-06-22]
- 初始发布
- 完成基本系统适配
- 完成基本功能实现

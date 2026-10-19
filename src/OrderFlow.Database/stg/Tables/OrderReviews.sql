CREATE TABLE stg.OrderReviews
(
    review_id nvarchar(max) NULL,
    order_id nvarchar(max) NULL,
    review_score nvarchar(max) NULL,
    review_comment_title nvarchar(max) NULL,
    review_comment_message nvarchar(max) NULL,
    review_creation_date nvarchar(max) NULL,
    review_answer_timestamp nvarchar(max) NULL,
    LoadRunId int NOT NULL CONSTRAINT DF_stg_OrderReviews_LoadRunId DEFAULT (0)
);
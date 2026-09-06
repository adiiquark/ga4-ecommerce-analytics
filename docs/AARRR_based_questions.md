The idea is to have 3 questions per stage in the AARRR framework

## Acquisition:
- 1. Which channel do most of the visitors come from? Does that same channel generate highest purchases hence revenue? Or is the highest volume channel the weakest in conversion of visitors to buyers?

- 2. Are visitors in different geographical locations generating more traffic on different devices? Could a trend be mapped between conversion and devices used? 

- 3. Does volume of traffic and purchase events peak at certain days of week and at certain times of day? Does this pattern appear across all geographical locations or some?   

## Activation:
- 4. What % of the first time visitors take any meaningful action(view_item or add_to_cart)? 

- 5. Of first time visitors who view an item what % goes on to add_to_cart in same session?  

- 6. Does first visit conversion to view_item/add_to_cart/purchase differ across devices and channels? 

## Retention:
- 7. What percentage of users (visitors) return (for any event) in 2, 3 and 4 weeks? What does the retention curve look like? 

- 8. Which geographical location give me more repurchasers and which channel do they come from? Do they purchase same items or different ones in the events of repurchase? 

- 9. Is there any particular average number of visits a customer has before they purchase?

- 10. Which items tend to be repurchased and which ones do not? What are our top 3 most purchased items? Which ones sell the worst? Do the most purchased items come from a particular channel? 

## Referral:

- 11. 12.  Customer referral behavior not directly answerable as the dataset does not contain any fields that indicate whether a customer refers others. Only indication is through traffic medium which tells whether a user visited the website via a referral link or any other way.  Question 1, 10 do cover possible referral questions based on the nature of the data. 

## Revenue
- 13. Which items and item categories sell more in which geo location? is there a relation between the items being sold and devices and channels being used??

- 14. Which items get returned the most? In which locations and are there same global trends of items being returned or different locations return different items? How much do refunds affect the revenue? 

- 15. What does the purchase revenue distribution look like? is it right skewed (concentrated in few large purchases), or spread more even? What is the mean vs median purchase value? 



------------------------------------------------------------------------------------------

## Filtering of the questions:

1. *Question:* channel volume vs conversion
    *Relevance?* Spend more on channels with high conversion instead of channel with more volume but lower conversion. 
    KEEP
2. *Question:* geography based trafic and conversion
    *Relevance?* Upon revisiting this question, it is similar to Q6 which deals with conversion and devices, will focus on that instead.  
    DROP, keep Q6 instead. 

3. *Question:* traffic and purchase on certain days based on geography
    *Relevance?*  Region specific campaigns can be scheduled 
    KEEP

4. *Question:* first visit and meaningful actions
    *Relevance?* Its akin to Q5 which deals with funnel, will keep that one.  
    DROP, keep Q5 instead

5. *Question:* rate of "first visit" to "add to cart" in same session
    *Relevance?* This explains 79.5% drop in the funnel already discovered in Guess 8 confirmation in 01_exploration.sql
    KEEP

6. *Question:* funnel conversion based on device and channel
    *Relevance?* Can focus attention on marketing and UX on less performing segments. 
    KEEP

7. *Question:* retention curve through weeks 1-4 
    *Relevance?* This is baseline for evaluation of loyalty 
    KEEP

8. *Question:* geography and channel of repurchasers and overlap of repurchased items
    *Relevance?* Since repurchasers volume is only about 500 records 
    DEFER

9. *Question:* No. of average visits before a purchase
    *Relevance* This is crucial for targetting customers
    KEEP

10. *Question:* Top/Bottom repurchased items
    *Relevance* Helps identify best performers but overlaps with Q13's items and item category angle, so will choose that for now
    DEFER

11. 12. *Question:* Referral behavior 
    *Relevance:* Since there is no field that indicates the connection between referring user and the resulting new user, this question cannot be answered. 
    DROP, LIMITATION

13. *Question:* item and item category popularity by geography and device
    *Relevance:* Helps with regional merchandising and stocking decisions
    KEEP

14. *Question:* Items and refunds
    *Relevance:* since there are no refundsin the data thos question is irrelevant to the project 
    DROP, LIMITATION

15. *Question:* channel volume vs conversion; Revenue distribution
    *What can be done?* Set realistiv AOV(average order value) expectations, flags skew
    KEEP
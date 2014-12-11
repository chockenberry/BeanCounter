# BeanCounter


## Introduction

### Show Me The Money!

For a quick demo, open the TestData/SafetyLight.beans document after you build the BeanCounter app. Now you know how well a flashlight app can sell in the iOS App Store. :-)

A majority of the sales for [Safety Light](http://safetylightapp.com/) came from a link at [Daring Fireball](http://daringfireball.net/linked/2009/12/29/safety-light) at the end of December 2009, but there was also a small blip in April 2012 thanks to a mention in Reader's Digest. As a way to thank my pal John Gruber for providing data for [my book on building and marketing iOS apps](http://appdevmanual.com/about/), I've donated the app's proceeds to his [family's charity](http://faan.convio.net/site/TR/2012Walks/2012Walks?px=1823877&pg=personal&fr_id=2177).


### What Problems Does This App Solve?

As the [Iconfactory](http://iconfactoryapps.com) has moved a significant part of our business to the App Store, we encountered some major discrepancies with the iTunes Connect financial reports:

* No per-product reporting in a common currency — How much did we earn in all regions with Product A vs. Product B?
* No aggregate reporting of multiple SKUs — How much did we earn with Product C and all its in-app purchases?
* No way to compute partner splits — How much we owe a partner who gets 50% of Product D earnings? 
* Hard to visualize the earnings across multiple regions —  How do launch sales for Product E in Japan compare to the US?
* No way to get the number of sales for a single product in a single region — How much do we owe fucking Lodsys for Twitterrific in-app upgrades in the US?

BeanCounter reads all the monthly financial reports through an import process. You then manually reconcile the deposit amounts from iTunes Connect to compute the exact exchange rate. That rate is then applied to one or more months of sales and result in earnings which are accurate to a fractional cent (we use decimal numbers throughout the application to ensure accuracy.)

Once we have accurate earnings, we use the data to plot charts and produce reports. The data for both the charts and report can be organized by product, a group of products or by partner in various date ranges. Both the charts and reports can be printed as PDF files and mailed/distributed as appropriate for your business.


### Why This Release?

This is an alpha release. It's also the first alpha release we've ever released outside of the Iconfactory. Why?

BeanCounter is useful, and it suits our needs. As we've learned with AppViz, there are also a lot of developers who do not trust a third-party with their iTunes Connect credentials. BeanCounter will let you keep track of your sales on a monthly basis and the data will never leave your hard drive.

Please ignore how bad this product looks: like I said, this is the first time we've let a product so ugly out of our internal group of testers.
 
But don't let the alpha designation give you any misgivings about the product's stability. We've been using it internally for _years_. We have paid partners and lawyers based on the information in the reports.


## Setup

We realize that getting this app setup is a bit tedious: you'll need to download or enter a lot of data before you get meaningful results. The `Safety Light.beans` file mentioned at the beginning of this file will show what that hard work can produce.

The following steps will help you get your own data into the app:


### Import Financial Reports

You'll need to download every report available from iTunes Connect. Once you are logged in, go to **Payment and Financial Reports > Earnings** and start clicking the **Download** links. Use the **Previous Months** buttons to go all the way back to your first month of sales.

Once you have all the reports saved on your local hard drive, open the `.gz` files so you have just the plain `.txt` files.

In BeanCounter, create a new document. Then select **Import Reports** from the source list and click **Import Financial Reports**. In the open file dialog, select the folder that contains the report `.txt` files.

When the import completes, save the document. You can now see charts and reports for "Units" and "Sales".


### Reconcile Monthly Deposits

To see charts and reports for "Earnings", you'll need to reconcile the deposits for every month. When you're logged into iTunes Connect, this information is available from **Payment and Financial Reports > Payments**. Use the **View Older Payments** button to select each month.

In BeanCounter, select **Reconcile Deposits** and set the the month to July 2010.

Starting at July 2010, you'll need to copy the information from Payments column on the web page to the Deposit column in BeanCounter. If there are any withholding taxes or other adjustments on the web page, you'll need to copy the sum to the Adjustments column in the app. Finally, if Apple shows that you carried a balance forward on July 2010, you'll need to enter the Beginning Balance amount into BeanCounter's Balance column as well (the balance will be computed automatically from this point on.)

As you enter the data, make sure that the amount shown in the web page's Post-Tax Subtotal column matches the Subtotal column. As you enter deposits, the total will update. After the last deposit is entered, press the **Reconcile** button to record the information in the database. Use the buttons at the top of the page to navigate through the months. It's also a good idea to Save the document periodically.

*Note:* iTunes Connect only has payment information available from July 2010 onward. If you have internal records for the deposits, such as bank statements or sales spreadsheets, you can go to **Account Settings** and change the earnings start date to July 2008. In this mode, you won't need to set the beginning balance for July 2010 as it will be computed automatically based on previous sales and deposits.

After you've gone through that pain and hassle, please make a backup of your deposit information using **Export Deposits** under the **Manage** menu (while the reconcile view is being displayed.) 


### Edit Products

Products are created automatically as they are imported. BeanCounter tracks information internally using the Apple ID, so you can rename the products as you see fit. For example, our first in-app purchase was named "Upgrade" but is much nicer when it's labeled as "Twitterrific Upgrade" in the charts and reports. You can also choose a color that helps you differentiate your products.

If you have a partner for a product, you can also use this screen to setup percentage splits. Multiple splits can be created, allowing scenarios where a partner gets 25% for a launch and then 50% as an ongoing incentive.


### Edit Groups

Groups can be added to create "logical products" from individual SKUs. For example, we have a "Ramp Champ" group that consists of the main app and each of its four in-app purchases. At present, a product can only be a member of one group.


### Edit Partners

If you collaborate with other individuals for a product, you can create a partner. A single partner can be involved with multiple products. (The split for each product is defined on the Edit Products screen.) 


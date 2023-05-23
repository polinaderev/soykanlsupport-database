# soykanlsupport-database
MySQL database design for https://t.me/frnlsupport project. 

The main code for this project is in a separate private repository. This repository has been created to show off my skills in relational database design. :)

## Project description

Our volunteer project is called Soyka NL Support (formerly FRNLsupport) and is dedicated to connecting Russian/Ukrainian-understanding refugees in the Netherlands in need of something with people who can give it to them. My 'colleagues' and I started it in spring 2022.

Example: a pregnant Ukrainian comes to NL and is about to give birth. She writes to us, ‘Hey, it’s almost time for the new person to come out of my belly but I have nothing for them. I would be grateful if someone could help me with clothes for the newborn. I live in Meppel now.’ We post her request in our channel, and soon there’s a channel subscriber who writes a comment, ‘I’ve got newborn clothes and I also happen to live in Meppel!’ We then connect the requester and the helper.

The project began in April, when our founder (not me) started manually collecting such requests from Telegram groups of Russian-understanding migrants in NL, putting them into a Google sheet manually (hence some irregularities in those early parts of our dataset), posting them into a Telegram channel (it’s like a Page on Facebook, where only admins can post but everyone can write comments) manually, and connecting the requesters with the helpers manually.

After a couple of weeks, I joined the project and we started recruiting manual admins for the Telegram channel and developers for a Telegram bot that was eventually meant to both collect requests from the refugees and offer relevant requests to the volunteers.

By now, we have a:

• Telegram bot https://t.me/frnlsupport_bot that mainly collects requests from refugees, i.e. acts as a Google form. It can also show requests to you in a Tinder-like manner, but this feature is not yet developed to a state convenient for usage;

• Monstruous Google sheet to which the bot records the data. It is also edited manually by the channel admins who read all requests and process some of them manually. By now, it has >15 tabs. The main tab can be edited by both the bot and the channel admins, which sometimes leads to people making some change unacceptable for the bot and a crash of the bot. It also simply doesn’t fit into a standard width screen. Here’s a screenshot of how just a piece of the main tab looks like (personal data removed):

![A sneak peek into our monstruous Google Sheet. Personal data removed](https://github.com/polinaderev/soykanlsupport-database/blob/main/img/googlesheet_sneakpeek.png)

So to me, our need of a proper database is clear;

• Telegram channel https://t.me/frnlsupport where the admins publish the most interesting and/or urgent requests manually;

• Map https://frnl-refugee-map.herokuapp.com/en where you can see requests by zip code and can also filter them by category and/or keyword(s). Requests are automatically translated to English via Google Translate API. The map gets the requests from the Google Sheet;

• >1000 helped refugees of the war and political oppression from the former Soviet countries, mainly Ukraine. :)

## Conceptual model

![Conceptual model of the database](https://github.com/polinaderev/soykanlsupport-database/blob/main/img/2_conceptualModel.png)

### ‘Customer’ journey of request submitting

The journey of submitting a request always begins with a requester **(table ‘People’)** using our Telegram bot. In addition to the request itself (‘Hi, I really need a new suitcase, thanks’), the bot also records a few pieces of data about the user and their request.

Most importantly, it automatically records the requester’s *user ID*. It’s a unique number that is given to a Telegram account once and forever. One can change their phone number, username, displayed name, but not their account ID.

The displayed name of the requester *(requester_first_name* and *requester_last_name)* are recorded as well, purely for the convenience of the admins who, with this information, will be able to double check if they’re contacting the right person regarding a certain request.

Sometimes we have to ban people from our project, for example, for almost ddosing us with senseless requests, or for unethical behavior of volunteers (inviting a requester for a date instead of helping them with their request). The is_banned field in the **‘People’** table is for this information.

The bot also asks the requester their current place of residence. At first, we simply asked people for their city names. After we ended up with variants such as ‘Purmorend’ and ‘Purnerend’ in this column, one of our developers changed the location question in the bot to ‘what’s your postcode?’ The bot feeds the postcode to Google Maps API and gets the *city name* and the postcode’s geographic *coordinates* automatically. Location-related data will get recorded to a special **‘Places’** table as one city and even one postcode may contain >1 person.

A *username* is a combination of symbols a Telegram user can assign to their account to be able to be found by it instead of their phone number. We deliberately do not collect people’s phone numbers because this information is too personal for our data storage practices. We collect usernames instead.

A username is changeable. People sometimes change their usernames because they want so. Therefore, I’m putting *usernames* into a separate table **(‘Usernames’)** with a many-usernames-to-one-person relationship.

The **Requests** are almost always in Russian, Ukrainian, or surzhik (a mix of Russian and Ukrainian). Therefore, to make it possible for non-Cyrillic-reading volunteers to help, the bot feeds a request *(‘description’)* to Google Translate API and gets an English version *(‘description_translation’)*.

To make requests more attractive for potential volunteers, we encourage requesters to elaborate on their request. A

>‘Hi everyone! We ran away from Kherson and found our temporary protection in the hospitable city of Eindhoven. Everyone around was so kind and gave us so much stuff we were missing. We now have so many belongings that we cannot carry them in our bag anymore. We would be grateful if someone could make us happy with a big suitcase.’

is better than,

>‘A suitcase is needed in Eindhoven, thanks.’

But as much as the detailedness of the requests is a blessing for the volunteers, as much it is of a curse for the data engineers of this project. Sometimes the requesters need >1 thing at once. Since it is tedious to write a large piece of text many times, they write it once and mention all their needs in one request. And we cannot yet fetch a list of requested items from a request automatically.

So what I’m suggesting to do in this new data model is to ask the requesters for (1) an elaborate request text as usually; (2) a comma-separated list of items they mentioned in their request (e.g. kettle, suitcase, pair of winter shoes). And to record the response (2) to a column *‘items_list_original’*.

This list given by a requester *(items_list_original)* will then get parsed and checked if it matches any possible items from the **‘Items’** table — Levenshtein distance in a comma-separated list is easy enough to be implemented by several of our developers, contrary to fishing out item names from a full text of the request, which is way more complicated. The parsed item list will then get double checked with the requester (‘is it correct that you requested: frying pan, smartphone, winter coat size M?’) and, when correct, recorded into the **‘Subrequests’** table, one item per line.

### Background work by the admins

After a request is submitted via the bot, it gets visible in the ‘database’ (currently a monstruous Google Sheet, hopefully a relational database soon) to the admins of the project. They choose which priority it has (1: urgent, 2: normal, 3: low) and whether to post it to the Telegram channel (https://t.me/frnlsupport) manually (interesting and/or urgent requests end up on this path). The admins will change the *status* of a **Request** or its **Subrequests** correspondingly (e.g. ‘posted’: posted in the channel, ‘ready’: proofread by humans and ready to be dispatched to the map and the Tinder-like branch in the bot, ‘partly_completed’: some items from the request have been promised to be given or have been given to the requester). I also suggest for the *status* of a **Request** and *status* of its **Subrequests** to be bound: e.g. if a *status* of a **Request** is changed, it will change for all of its **Subrequests** correspondingly automatically.

If a **Subrequest** is posted in the channel, then it’s a good practice to put the link to the post into the database *(post_link)*.

### ‘Customer’ journey of fulfilling a request

Although the ‘Tinder’ branch of the bot is not popular now, it does exist and may be optimized for a better user experience in the future. Therefore, I’m also including data necessary for this branch into the database, into the respective table **(‘People’)**. Namely, we ask the users of this branch about the filters they would prefer: whether they would like to see requests from the whole Netherlands or from their city + 5 km only *(prefers_whole_nl)* and their preferred categories/keywords of requests. The latter has to be recorded into a separate matching table because an item (type) may be preferred by >1 volunteer and a volunteer may prefer >1 item (type).

Volunteers fulfil (parts of) **Requests**. I.e. volunteers fulfil **Subrequests**. E.g. a request is, ‘we need a multicooker and a fridge’ and some volunteer is ready to buy a multicooker for the requester, but not a fridge. Each **Subrequest** may only be fulfilled by zero volunteers or one volunteer. If a **Subrequest** requires >1 volunteer, it is to be divided manually by the admins to the corresponding number of **Subrequests**. The volunteer and status info in the **Subrequests** table will be filled in either manually (if a volunteer was found through the channel) or automatically (if the volunteer has used the bot to agree to fulfil a **Subrequest**). Since my data model assumes volunteers fulfil **Subrequests**, not Requests, a modification of the bot will be needed here so that in response to a volunteer tapping/clicking the ‘I will help with this request’ button, it will offer all **Subrequests** for the corresponding **Request** and ask the volunteer with which **Subrequests** in particular they would like to help. I would like to delegate this modification of the bot to my developer colleagues. :)

Should a potential volunteer use our map (https://frnl-refugee-map.herokuapp.com/en) for choosing a request they would like to fulfil, the map will redirect them to the Telegram bot for agreeing to fulfil that request. So the fact that we also have the map as a volunteer entry point does not change anything in the database.

For statistics, I would like to suggest to record which of the 3 ‘canonical’ volunteer entry paths (via the channel, bot or map) was used for each fulfilled **Subrequest**-volunteer match *(fulfil_src).**

### ‘Customer’ journey of leaving feedback

In addition to the ‘submit a request’ and ‘look for requests I could fulfil’ branches in our bot, we also have a branch for feedback in there. Hence, I suggest that there’s a table **‘Feedback’** in our database. Currently, we only collect text feedback *(description)* and in addition ask people if we can publish their feedback in the channel *(permission to publish).* The text is currently not automatically translated into English via Google Translate API, but I suggest that it does in the future *(description_translation).* Admins also note in this table whether a piece of feedback has been published *(status).*

I also suggest that we collect **Files** as a part of feedback — it is always nice when text is complemented with a photo. **Files** have their *name* and *path.* I suggest to also store information about *size* of the **Files** — to be able to get an idea when our file storage is (close to) full.

![EER model of the database](https://github.com/polinaderev/soykanlsupport-database/blob/main/img/2_model_eer.png)

## Reflection

### Advantages of a relational database for this project

✓ We will finally resolve the request vs subrequest problem because it’s currently organized very inconveniently for both admins and users of the bot.
✓ Although one can introduce cell content restrictions in Google Sheets, a database is more restrictive and will therefore ensure more consistent data. E.g. admins won’t be able to accidentally change a request id.
✓ The nature of the data (‘customers’ (requesters) with ‘orders’ (requests) and ‘sellers’ (volunteers)) is perfect for a relational database.

### Disadvantages of a relational database for this project

- >90% of our admins are not familiar with databases. So we’ll have to either teach them how to use the database, or invent some mirroring of the database to Excel files/Google sheets for them.
- The database structure I have suggested here will require some reprogramming of our Telegram bot. I.e. more human-hours of programming and testing which are scarce in a purely enthusiasm-driven project.

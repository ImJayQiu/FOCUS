class WikiPage < ApplicationRecord

    mount_uploader :image1, WikiImgsUploader 
    mount_uploader :image2, WikiImgsUploader 

end
